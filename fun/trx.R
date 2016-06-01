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
    system(print(cmd, quote=F))
  }
  
  read <- function(inst, site, nf=1, pattern='.*\\.{1}dat') {
    hdr <- switch(inst,
                  '2bo3'  = c('Time_UTC', 'O3_ppbv', 'CellT_C', 'CellP_hPa',
                              'Flow_ccmin', 'Date', 'Time'),
                  'gps'    = c('Time_UTC', 'NMEA_ID', 'fixtime', 'lat', 'NS', 'lon',
                               'EW', 'quality', 'nsat', 'hordilut','alt', 'alt_unit',
                               'geoidht', 'geoidht_unit', 'DGPS_id','checksum'),
                  'lgr' = c('Time_UTC', 'valve', 'lgrtime', 'ch4_ppm', 'ch4_ppm_sd',
                            'h2o_ppm', 'h2o_ppm_sd', 'co2_ppm', 'co2_ppm_sd', 
                            'CH4d_ppm', 'CH4d_ppm_sd', 'CO2d_ppm', 'CO2d_ppm_sd',
                            'GasP_torr', 'GasP_torr_sd', 'GasT_C', 'GasT_C_sd', 'AmbT_C',
                            'AmbT_C_sd', 'RD0_us', 'RD0_us_sd', 'RD1_us', 'RD1_us_sd',
                            'Fit_Flag', 'MIU_v', 'MIU'),
                  'metone' = c('Time_UTC', 'PM25_ugm3', 'flow_lpm', 'T_C', 'RH_pct',
                               'P_hPa', 'unk', 'code'),
                  'met'    = c('Time_UTC', 'case_T_C', 'case_RH_pct', 'case_T2_C',
                               'case_P_hPa', 'amb_T_C', 'amb_RH_pct', 'box_T_C'))
    
    files <- dir(file.path('data', site, 'raw', inst), pattern=pattern, full.names=T)
    if (!is.null(nf)) files <- tail(files, nf)
    
    data <- lapply(files, function(x, inst)
    {
      try({
        ln <- readLines(x, skipNul=T, encoding='latin1')
        if (inst == 'gps') ln <- grep('$GPGGA', ln, value=T, fixed=T)
        return(ln)
      })
    }, inst=inst) %>%
      unlist() %>%
      iconv('latin1', 'ASCII', sub='') %>%
      uataq::breakstr(ncol=length(hdr))
    
    colnames(data) <- hdr
    for (col in 2:ncol(data)) {
      try(
        data[[col]] <- as.numeric(data[[col]])
      )
    }
    
    if(nrow(data) < 1) return(NULL)
    
    data <- data %>%
      mutate(Time_UTC = as.POSIXct(Time_UTC, tz='UTC', format='%Y-%m-%d %H:%M:%OS'),
             site_id = site)
    data
  }
  
  # Directory structure and data ------------------------------------------------
  if (reset[[site]] | global_reset) {
    system(paste0('rm -r ', 'data/', site, '/parsed/*')) 
    system(paste0('rm -r ', 'data/', site, '/geoloc/*'))
    dir.create(file.path('data', site, 'parsed'), 
               showWarnings=FALSE, recursive=TRUE, mode='0755')
    dir.create(file.path('data', site, 'geoloc'), 
               showWarnings=FALSE, recursive=TRUE, mode='0755')
    nf <- NULL
  } else {
    if (!run[[site]]) stop('Site processing disabled in global.R')
    nf <- 1
    pull_trx(ip, site, port)
  }
  
  # Read data and update archives ---------------------------------------------
  d        <- lapply(inst, read, site=site, nf=nf)
  names(d) <- inst
  
  if ('metone' %in% names(d)) {
    d$metone$PM25_ugm3 <- d$metone$PM25_ugm3 * 1000 
  }
  if ('gps' %in% names(d)) {
    d$gps <- d$gps %>%
      mutate(lat = floor(lat/100)+(lat-floor(lat/100)*100)/60,
             lon = -(floor(lon/100)+(lon-floor(lon/100)*100)/60))
  }
  
  for(i in inst){
    uataq::archive(d[[i]], path=file.path(
      'data', site, 'parsed', i, '%Y_%m_parsed.dat'))
  }
  
  # Aggregate data from different sources -------------------------------------
  trx <- bind_rows(
    d$gps[c('Time_UTC', 'lat', 'lon', 'alt')],
    d$lgr[c('Time_UTC', 'CO2d_ppm', 'CH4d_ppm')],
    d$`2bo3`[c('Time_UTC', 'O3_ppbv')],
    d$metone[c('Time_UTC', 'PM25_ugm3')],
    d$met[c('Time_UTC', 'case_T_C', 'case_RH_pct','case_P_hPa', 
            'amb_T_C', 'amb_RH_pct', 'box_T_C')])
  
  trx <- trx[rowSums(!is.na(trx[-1])) > 0, ]
  
  trx_s <- trx %>%
    arrange(Time_UTC) %>%
    group_by(Time_UTC = as.POSIXct(trunc(Time_UTC))) %>%
    summarize_each(funs(mean(., na.rm=T))) %>%
    mutate(site_id = site)
  
  uataq::archive(trx_s, path=file.path(
    'data', site, 'geoloc', '%Y_%m_geoloc.dat'))
  
  # Geolocation by linear interpolation ---------------------------------------
  trx_interp <- bind_cols(
    data_frame(Time_UTC = trx_s$Time_UTC),
    as_data_frame(lapply(trx_s[-1], function(y,x){
      if ('numeric' %in% class(y)) {
        uataq::na_interp(y,x)
      } else return(y)
    }, x=trx_s$Time_UTC))
  )
  
  trx_interp %>%
    filter(Time_UTC > Sys.time() - 3600 * 2) %>%
    (function(x) {
      if(nrow(x) > 0) 
        saveRDS(x, file.path('data', site, 'recent.rds'))
    }) %>%
    invisible()
  
})
lock_remove()
