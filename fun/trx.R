# TRAX processing functions.
# Sourced by trx processing scripts.
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
  pull_trx <- function(ip, site, port) {
    cmd <- paste0('/usr/bin/rsync --timeout=60 -vrutzhO -e "/usr/bin/ssh -i ',
                  '/uufs/chpc.utah.edu/common/home/u0791983/.ssh/id_rsa -p ', port,
                  '" pi@', ip, ':/home/pi/data/ ',
                  '/uufs/chpc.utah.edu/common/home/lin-group2/measurements/data/', 
                  site, '/raw/')
    system(cmd)
  }
  
  read <- function(inst, site, nf=1, pattern='.*\\.{1}dat') {
    hdr <- switch(inst,
                  '2bo3'  = c('Time_common', 'O3_ppbv', 'CellT_C', 'CellP_hPa',
                              'Flow_ccmin', 'Date', 'Time'),
                  'gps'    = c('Time_common', 'NMEA_ID', 'fixtime', 'lat', 'NS', 'lon',
                               'EW', 'quality', 'nsat', 'hordilut','alt', 'alt_unit',
                               'geoidht', 'geoidht_unit', 'DGPS_id','checksum'),
                  'lgr' = c('Time_common', 'valve', 'lgrtime', 'ch4_ppm', 'ch4_ppm_sd',
                            'h2o_ppm', 'h2o_ppm_sd', 'co2_ppm', 'co2_ppm_sd', 
                            'ch4d_ppm', 'ch4d_ppm_sd', 'co2d_ppm', 'co2d_ppm_sd',
                            'GasP_torr', 'GasP_torr_sd', 'GasT_C', 'GasT_C_sd', 'AmbT_C',
                            'AmbT_C_sd', 'RD0_us', 'RD0_us_sd', 'RD1_us', 'RD1_us_sd',
                            'Fit_Flag', 'MIU_v', 'MIU_d'),
                  'metone' = c('Time_common', 'PM25_ugm3', 'flow_lpm', 'T_C', 'RH_pct',
                               'P_hPa', 'unk', 'code'),
                  'met'    = c('Time_common', 'case_T_C', 'case_RH_pct', 'case_T2_C',
                               'case_P_hPa', 'amb_T_C', 'amb_RH_pct', 'box_T_C'))
    
    files <- dir(file.path('data', site, 'raw', inst), pattern=pattern, full.names=T)
    if(!is.null(nf)) files <- tail(files, nf)
    
    raw <- lapply(files, function(x){ try(readLines(x, skipNul=T)) }) %>%
      bind_rows()
    
    
    data <- uataq::breakstr(raw)
    colnames(data) <- hdr
    for(col in 2:ncol(data)) data[ ,col] <- as.numeric(data[ ,col])
    
    if(nrow(data) < 1) return(NULL)
    
    data$Time_UTC <- as.POSIXct(data$Time_UTC, tz='UTC', format='%Y-%m-%d %H:%M:%S')
    data
  }
  
  # Directory structure and data ------------------------------------------------
  pull_trx(ip, site, port)
  
  if (reset[[site]] | global_reset) {
    system(paste0('rm ', 'data/', site, '/parsed/*')) 
    system(paste0('rm ', 'data/', site, '/geoloc/*'))
    dir.create(file.path('data', site, 'parsed'), 
               showWarnings=FALSE, recursive=TRUE, mode='0755')
    dir.create(file.path('data', site, 'geoloc'), 
               showWarnings=FALSE, recursive=TRUE, mode='0755')
  }
  
  # Read data and update archives ---------------------------------------------
  d        <- lapply(inst, read, site=site, nf=nf)
  names(d) <- inst
  
  if ('metone' %in% names(d)) {
    d$metone$PM25_ugm3 <- d$metone$PM25_ugm3 * 1000 
  }
  if ('gps' %in% names(d)) {
    d$gps$lat <- with(d$gps, floor(lat/100)+(lat-floor(lat/100)*100)/60)
    d$gps$lon <- with(d$gps, -(floor(lon/100)+(lon-floor(lon/100)*100)/60))
  }
  
  for(i in inst){
    uataq::archive(d[[i]], path=file.path(
      'data', site, 'parsed', i, '%Y_%m_parsed.dat'))
  }
  
  # Geolocation by linear interpolation ---------------------------------------
  trx <- bind_rows(
    d$gps[c('Time_UTC', 'lat', 'lon', 'alt')],
    d$lgr[c('Time_UTC', 'co2d_ppm', 'ch4d_ppm')],
    d$`2bo3`[c('Time_UTC', 'O3_ppbv')],
    d$metone[c('Time_UTC', 'PM25_ugm3')],
    d$met[c('Time_UTC', 'case_T_C', 'case_RH_pct','case_P_hPa', 
            'amb_T_C', 'amb_RH_pct', 'box_T_C')])
  
  trx_s <- trx %>%
    arrange(Time_UTC) %>%
    group_by(Time_UTC = as.POSIXct(trunc(Time_UTC))) %>%
    summarize(lat = mean(lat, na.rm=T),
              lon = mean(lon, na.rm=T),
              alt = mean(alt, na.rm=T),
              co2d_ppm = mean(co2d_ppm, na.rm=T),
              ch4d_ppm = mean(ch4d_ppm, na.rm=T),
              O3_ppbv = mean(O3_ppbv, na.rm=T),
              PM25_ugm3 = mean(PM25_ugm3, na.rm=T),
              case_T_C = mean(case_T_C, na.rm=T),
              case_RH_pct = mean(case_RH_pct, na.rm=T),
              case_P_hPa = mean(case_P_hPa, na.rm=T),
              amb_T_C = mean(amb_T_C, na.rm=T),
              amb_RH_pct = mean(amb_RH_pct, na.rm=T),
              box_T_C = mean(box_T_C, na.rm=T))
  
  trx_interp <- bind_cols(
    data_frame(Time_UTC = trx_s$Time_UTC),
    as_data_frame(lapply(trx_s[-1], uataq::na_interp, x=trx_s$Time_UTC))
  )
  
  uataq::archive(trx_interp, path=file.path(
    'data', site, 'geoloc', '%Y_%m_geoloc.dat'))
  
  trx_interp %>%
    filter(Time_UTC > Sys.time() - 3600 * 2) %>%
    (function(x) {
      if(nrow(x) > 0) 
        saveRDS(x, file.path(data, site, 'recent.rds'))
    }) %>%
    invisible()
  
})
lock_remove()
