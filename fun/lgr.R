# LGR site processing script.
# Sourced by Uinta Basin and WBB processing scripts.
# Ben Fasoli

setwd('/uufs/chpc.utah.edu/common/home/lin-group2/measurements/')
source('lair-proc/global.R')
lock_create()

try({
  # Packages --------------------------------------------------------------------
  lib <- '/uufs/chpc.utah.edu/common/home/u0791983/.Rpackages'
  library(dplyr,   lib.loc=lib)
  library(readr,   lib.loc=lib)
  library(uataq,   lib.loc=lib)
  
  # Functions -------------------------------------------------------------------
  pull_lgr <- function(ip, site) {
    cmd <- paste0('/usr/bin/rsync -vrutzhO --stats --exclude="archive/" -e ',
                  '"/usr/bin/ssh -i /uufs/chpc.utah.edu/common/home/u0791983/.ssh/id_rsa" ',
                  'lgr@', ip, ':/home/lgr/data/ ',
                  '/uufs/chpc.utah.edu/common/home/lin-group2/measurements/data/', site, '/raw/')
    system(print(cmd, quote=F))
  }
  
  
  # Directory structure and data ------------------------------------------------
  check_bad()
  
  if (reset[[site]] | global_reset) {
    system(paste0('rm ', 'data/', site, '/parsed/*')) 
    system(paste0('rm ', 'data/', site, '/calibrated/*'))
    dir.create(file.path('data', site, 'parsed'), 
               showWarnings=FALSE, recursive=TRUE, mode='0755')
    dir.create(file.path('data', site, 'calibrated'), 
               showWarnings=FALSE, recursive=TRUE, mode='0755')
    
    cal_all <- T
  } else {
    cal_all <- F
    pull_lgr(ip, site)
  }
  
  # Determine files to be read --------------------------------------------------
  # Unzip necessary compressed data packets
  dir(file.path('data', site, 'raw'), '\\.{1}txt\\.{1}zip', full.names=T, recursive=T) %>%
    lapply(function(zf) {
      tf <- tools::file_path_sans_ext(zf)
      if (file.exists(tf) && round(file.mtime(zf))==round(file.mtime(tf))) {
        return(NULL)
      } else {
        # If the ASCII .txt file does not exist or the modified time does not
        # match that of the .zip file, overwrite the text file with data from the
        # .zip file and update the modified times of the two
        system(paste('unzip -o', zf, '-d', dirname(zf)))
        system(paste('touch', zf, tf))
      }
    }) %>% 
    invisible()
  
  tfs <- dir(file.path('data', site, 'raw'), 'f....\\.{1}txt$', full.names=T, recursive=T)
  if (!cal_all) {
    # Sort by file modification time since older versions of LGR's software
    # are named non-sequentially
    tfs <- tfs[order(file.mtime(tfs))]
    tfs <- tail(tfs, 2)
  }
  
  # Read files ------------------------------------------------------------------
  raw <- lapply(tfs, function(tf) {
    df <- tryCatch(suppressWarnings(
      read_csv(tf, col_names=F, skip=2, na=c('TO', '', 'NA'), 
               locale=locale(tz='UTC'))),
      error=function(e){NULL})
    
    if(is.null(df) || ncol(df) < 23 || ncol(df) > 24) return(NULL)
    
    # Adapt column names depending on LGR software version.
    #  2013-2014 version has 23 columns.
    #  2014+ version has 24 columns (MIU split into valve and description).
    colnames(df) <- switch(as.character(ncol(df)),
                           '23' = c('Time_UTC', 'CH4_ppm', 'CH4_ppm_sd', 'H2O_ppm',
                                    'H2O_ppm_sd', 'CO2_ppm', 'CO2_ppm_sd', 'CH4d_ppm',
                                    'CH4d_ppm_sd', 'CO2d_ppm', 'CO2d_ppm_sd', 'GasP_torr',
                                    'GasP_torr_sd', 'GasT_C', 'GasT_C_sd', 'AmbT_C',
                                    'AmbT_C_sd', 'RD0_us', 'RD0_us_sd', 'RD1_us',
                                    'RD1_us_sd', 'Fit_Flag', 'ID'),
                           '24' = c('Time_UTC', 'CH4_ppm', 'CH4_ppm_sd', 'H2O_ppm',
                                    'H2O_ppm_sd', 'CO2_ppm', 'CO2_ppm_sd', 'CH4d_ppm',
                                    'CH4d_ppm_sd', 'CO2d_ppm', 'CO2d_ppm_sd', 'GasP_torr',
                                    'GasP_torr_sd', 'GasT_C', 'GasT_C_sd', 'AmbT_C',
                                    'AmbT_C_sd', 'RD0_us', 'RD0_us_sd', 'RD1_us',
                                    'RD1_us_sd', 'Fit_Flag', 'MIU_v', 'ID'))
    dplyr::filter(df, !is.na(ID))
  }) %>% 
    bind_rows() %>%
    mutate(Time_UTC = as.POSIXct(Time_UTC, tz='UTC', format='%m/%d/%Y %H:%M:%S')) %>%
    filter(!is.na(Time_UTC)) %>%
    arrange(Time_UTC)
  
  if ('MIU_v' %in% names(raw)) raw <- select(raw, -MIU_v)
  
  # UTC Changeover --------------------------------------------------------------
  # Remove data during 12-29-2015 to 12-30-2015 during which the sites were
  # being changed from local time to UTC.
  raw <- raw %>%
    filter(Time_UTC < as.POSIXct('2015-12-29', tz='UTC') |
             Time_UTC > as.POSIXct('2015-12-30', tz='UTC')) %>%
    mutate(pre_utc = Time_UTC > as.POSIXct('2015-12-30', tz='UTC'))
  
  raw$Time_UTC[raw$pre_utc] <- as.POSIXct(format(raw$Time_UTC[raw$pre_utc], 
                                                 tz='UTC'), tz='Denver')
  
  # Remove bad data -------------------------------------------------------------
  # remove_bad() found in global.R
  parsed <- raw %>% 
    select(-pre_utc) %>%
    filter(!duplicated(Time_UTC)) %>%
    remove_bad(site) %>%
    filter(nchar(ID) > 0,
           GasP_torr > 135,
           GasP_torr < 145) %>%
    mutate(ID = gsub('\\s+|V:{1}[0-9]', '', ID),
           ID = gsub('^~', '', ID),
           ID = gsub('unknown', NA, ID, ignore.case=T),
           site_id = site) %>%
    filter(!is.na(ID))
  
  ID_split <- stringr::str_split_fixed(parsed$ID, '~', 2)
  ID_split[grepl('atmosphere', ID_split[ ,1], ignore.case=T)] <- '-10'
  ID_split[grepl('flush', ID_split[ ,1], ignore.case=T)]      <- '-99'
  ID_split <- matrix(as.numeric(ID_split), ncol=2)
  
  parsed$ID_co2 <- ID_split[ ,1]
  parsed$ID_ch4 <- ID_split[ ,2]
  
  uataq::archive(parsed, path=file.path('data', site, 'parsed/%Y_%m_parsed.dat'))
  
  # Calibrations ----------------------------------------------------------------
  if (!cal_all) {
    files <- tail(dir(file.path('data', site, 'parsed'), full.names=T), 2)
    parsed <- lapply(files, read_csv, locale=locale(tz='UTC'),
                     col_types='T------d-d--------------dd') %>% bind_rows()
  }
  
  cal_co2 <- with(parsed, 
                  uataq::calibrate(Time_UTC, CO2d_ppm, ID_co2,
                                   auto=T, er_tol=0.15, dt_tol=18000))
  
  cal_ch4 <- with(parsed, 
                  uataq::calibrate(Time_UTC, CH4d_ppm, ID_ch4,
                                   auto=T, er_tol=0.15, dt_tol=18000))
  
  cal <- data_frame(Time_UTC     = cal_co2$time,
                    CO2d_ppm_cal = cal_co2$cal,
                    CO2d_ppm_raw = cal_co2$raw,
                    m_co2        = cal_co2$m,
                    b_co2        = cal_co2$b,
                    n_co2        = cal_co2$n,
                    CH4d_ppm_cal = cal_ch4$cal,
                    CH4d_ppm_raw = cal_ch4$raw,
                    m_ch4        = cal_ch4$m,
                    b_ch4        = cal_ch4$b,
                    n_ch4        = cal_ch4$n) %>%
    filter(n_co2 > 0 | n_ch4 > 0) %>%
    mutate(site_id = site)
  
  uataq::archive(cal, path=file.path('data', site, 
                                     'calibrated/%Y_%m_calibrated.dat'))
})
lock_remove()
