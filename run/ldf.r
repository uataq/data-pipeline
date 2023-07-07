# James Mineau

site   <- 'ldf'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group9/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]

lock_create()


try({
  # LGR UGGA
  instrument <- 'lgr_ugga'
  proc_init()
  
  path <- file.path('data', site, instrument, 'raw')
  
  if (!site_config$reprocess) {
    remote <- paste0('pi@', site_config$ip, ':/home/pi/data/lgr/')
    local <- file.path('data', site, instrument, 'raw/')
    rsync(from = remote, to = local, port = site_config$port)
    
    lt <- dir(file.path('data', site, instrument, 'qaqc'), full.names = T) %>%
      tail(1) %>%
      get_last_time(format = '%Y-%m-%d') %>%
      as.Date()
    batches <- format(seq(lt, Sys.Date(), by = 1), '*%Y_%m_%d*')
  } else {
    # Reprocess daily batches
    batches <- unique(substring(dir(path), 1, 11))
  }
  
  nd <- lapply(batches, function(batch) {
    # Define file grouping to expand with unix cat
    selector <- file.path(path, paste0(batch, '*'))
    # 1s LGR data contains 0 for al l standard deviation columns (intended for 
    # longer-term averaged measurements) - drop the extra columns
    colnums <- '1,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24'
    # Pattern matching passed as command args to grep
    # / : date separator in LGR datetime syntax
    # e : exponent notation in LGR output
    pattern <- c('/', 'e')
    
    nd <- read_pattern(selector, colnums, pattern)
    if (nrow(nd) < 1) return(NULL)
    colnames(nd) <- c('Time_UTC', 'ID', 'CH4_ppm', 'CH4_ppm_sd',
                      'H2O_ppm', 'H2O_ppm_sd', 'CO2_ppm', 'CO2_ppm_sd', 'CH4d_ppm',
                      'CH4d_ppm_sd', 'CO2d_ppm', 'CO2d_ppm_sd', 'Cavity_P_torr',
                      'Cavity_P_torr_sd', 'Cavity_T_C', 'Cavity_T_C_sd', 'Ambient_T_C', 
                      'Ambient_T_C_sd', 'RD0_us', 'RD0_us_sd', 'RD1_us', 'RD1_us_sd', 'Fit_Flag')
    
    nd$Time_UTC <- fastPOSIXct(nd$Time_UTC, tz = 'UTC')
    attributes(nd$Time_UTC)$tzone <- 'UTC'
    
    # Remove whitespace from padded IDs
    nd$ID <- str_trim(nd$ID)
    
    for (i in 3:ncol(nd)) {
      nd[[i]] <- suppressWarnings(as.numeric(nd[[i]]))
    }
    
    nd <- nd %>%
      dplyr::filter(!is.na(Time_UTC), !is.na(ID),
                    !is.na(CO2d_ppm), !is.na(CH4d_ppm)) 
    
    if (nrow(nd) < 1) return(NULL)
  }) %>%
    bind_rows()

  # Sort by time
  nd <- nd %>%
      arrange(Time_UTC)
    
  # Arrange columns to match non-pi sites
  nd <- nd[,data_config[[instrument]]$qaqc$col_names[1:ncol(nd)]]
    
  nd <- lgr_ugga_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- lgr_ugga_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  
})


lock_remove()
