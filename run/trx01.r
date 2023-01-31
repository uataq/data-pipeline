# Ben Fasoli

site   <- 'trx01'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group9/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]

lock_create()

if (!site_config$reprocess && 
    !cr1000_is_online(paste(sep=':', site_config$ip, 9191))) {
  lock_remove()
  stop('Unable to connect to ', site_config$ip)
}

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
    # Reprocess monthly batches
    batches <- unique(substring(dir(path), 1, 11))
  }
  
  for (batch in batches) {
    # Define file grouping to expand with unix cat
    selector <- file.path(path, paste0(batch, '*'))
    # 1s LGR data contains 0 for al l standard deviation columns (intended for 
    # longer-term averaged measurements) - drop the extra columns
    colnums <- '1,2,4,6,8,10,12,14,16,18,20,22'
    # Pattern matching passed as command args to grep
    # / : date separator in LGR datetime syntax
    # e : exponent notation in LGR output
    pattern <- c('/', 'e')
    
    nd <- read_pattern(selector, colnums, pattern)
    if (nrow(nd) < 1) next
    colnames(nd) <- c('Time_UTC', 'ID', 'CH4_ppm', 'H2O_ppm', 'CO2_ppm', 
                      'CH4d_ppm', 'CO2d_ppm', 'Cavity_P_torr', 'Cavity_T_C', 
                      'Ambient_T_C', 'RD0_us', 'RD1_us')
    
    nd$Time_UTC <- fastPOSIXct(nd$Time_UTC, tz = 'UTC')
    attributes(nd$Time_UTC)$tzone <- 'UTC'
    
    for (i in 2:ncol(nd)) {
      nd[[i]] <- suppressWarnings(as.numeric(nd[[i]]))
    }
    
    nd <- nd %>%
      dplyr::filter(!is.na(Time_UTC), !is.na(ID),
                    !is.na(CO2d_ppm), !is.na(CH4d_ppm)) %>%
      dplyr::filter(Time_UTC >= as.POSIXct('2014-12-01', tz = 'UTC'),
                    Time_UTC <= Sys.time()) %>%
      arrange(Time_UTC)
    
    if (nrow(nd) < 1) next
    
    # Apply tank reference values from pipeline/config
    tank_vals <- read_csv('pipeline/config/trx01_tanks.csv',
                          locale = locale(tz = 'UTC', date_format = '%m/%d/%Y'),
                          col_types = 'D_dd') %>%
      mutate(t1 = as.POSIXct(Date),
             t2 = c(t1[2:n()], Sys.time()))
    for (i in c('t1', 't2')) attributes(tank_vals[[i]])$tzone <- 'UTC'
    for (i in 1:nrow(tank_vals)) {
      mask <- nd$Time_UTC >= tank_vals$t1[i] &
        nd$Time_UTC < tank_vals$t2[i] &
        nd$ID == 2
      nd$ID[mask] <- paste0('~', tank_vals$CO2_ref[i], 
                            '~', tank_vals$CH4_ref[i])
    }
    nd$ID[nd$ID %in% c('-2', '-1')] <- '~-99~-99'
    nd$ID[nd$ID %in% '1'] <- '~-10~-10'
    nd <- lgr_ugga_qaqc()
    
    # trx01 lgr ugga automated qaqc
    nd$QAQC_Flag[with(nd, CO2d_ppm < 300 | CO2d_ppm > 5000)] <- -1
    nd$QAQC_Flag[with(nd, CH4d_ppm < 1 | CH4d_ppm > 100)] <- -1
    
    update_archive(nd, data_path(site, instrument, 'qaqc'))
    nd <- lgr_ugga_calibrate()
    update_archive(nd, data_path(site, instrument, 'calibrated'))
  }
})

try({
  # GPS
  instrument <- 'gps'
  proc_init()
  
  path <- file.path('data', site, instrument, 'raw')
  
  if (!site_config$reprocess) {
    remote <- paste0('pi@', site_config$ip, ':/home/pi/data/gps/')
    local <- file.path('data', site, instrument, 'raw/')
    rsync(from = remote, to = local, port = site_config$port)
    
    lt <- dir(file.path('data', site, instrument, 'qaqc'), full.names = T) %>%
      tail(1) %>%
      get_last_time(format = '%Y-%m-%d') %>%
      as.Date()
    batches <- format(seq(lt, Sys.Date(), by = 1), '*%Y_%m_%d*')
  } else {
    # Reprocess monthly batches
    batches <- unique(substring(dir(path), 1, 11))
  }
  
  for (batch in batches) {
    
    # Define file grouping to expand with unix cat
    selector <- file.path(path, paste0(batch, '*'))
    # 1s GPGGA strings contain several unused columns (DGPS ref id, etc.)
    colnums <- '1,3,4,6,8,9,10,11'
    # Pattern matching passed as command args to grep
    # GPGGA : prefix of location and fix data strings
    # [*] : match literal asterisk found in GPGGA checksum
    pattern <- c('GPGGA', '[*]')
    
    nd <- read_pattern(selector, colnums, pattern)
    if (nrow(nd) < 1) next
    nd <- nd %>%
      setNames(c('Time_UTC', 'GPS_Time_UTC', 'Lati_deg', 'Long_deg',
                 'Fix_Quality', 'NSat', 'Location_Uncertainty_m',
                 'Altitude_m')) %>%
      mutate_at(c('Lati_deg', 'Long_deg'), funs(suppressWarnings(gps_dm2dd(.))))
    
    nd$Long_deg <- -nd$Long_deg
    nd$Time_UTC <- fastPOSIXct(nd$Time_UTC, tz = 'UTC')
    attributes(nd$Time_UTC)$tzone <- 'UTC'
    
    for (i in 2:ncol(nd)) {
      nd[[i]] <- suppressWarnings(as.numeric(nd[[i]]))
    }
    
    nd <- nd %>%
      dplyr::filter(!is.na(Time_UTC), !is.na(NSat)) %>%
      arrange(Time_UTC)
    
    if (nrow(nd) < 1) next
    
    # Initialize qaqc flag
    nd$QAQC_Flag <- 0
    
    # Apply manual qaqc definitions in bad/site/instrument.csv
    nd <- bad_data_fix(nd)
    update_archive(nd, data_path(site, instrument, 'qaqc'))
    update_archive(nd, data_path(site, instrument, 'calibrated'))
  }
})

try({
  # 2B Ozone
  instrument <- '2bo3'
  proc_init()
  
  path <- file.path('data', site, instrument, 'raw')
  
  if (!site_config$reprocess) {
    stop('2b data up to date - nothing to be done.')
    # remote <- paste0('pi@', site_config$ip, ':/home/pi/data/2bo3/')
    # local <- file.path('data', site, instrument, 'raw/')
    # rsync(from = remote, to = local, port = site_config$port)
    # 
    # lt <- dir(file.path('data', site, instrument, 'qaqc'), full.names = T) %>%
    #   tail(1) %>%
    #   get_last_time(format = '%Y-%m-%d') %>%
    #   as.Date()
    # batches <- format(seq(lt, Sys.Date(), by = 1), '*%Y_%m_%d*')
  } else {
    # Reprocess monthly batches
    batches <- unique(substring(dir(path), 1, 10))
  }
  
  for (batch in batches) {
    # Define file grouping to expand with unix cat
    selector <- file.path(path, paste0(batch, '*'))
    # 1s LGR data contains 0 for al l standard deviation columns (intended for 
    # longer-term averaged measurements) - drop the extra columns
    colnums <- 1:5
    # Pattern matching passed as command args to grep
    # / : date separator in 2b datetime syntax
    # -v e : invert matching any lines containing exponential notation
    pattern <- c('/', '-v e')
    
    nd <- read_pattern(selector, colnums, pattern)
    if (nrow(nd) < 1) next
    nd <- nd %>%
      setNames(c('Time_UTC', 'O3_ppb', 'Cavity_T_C', 'Cavity_P_hPa', 
                 'Flow_ccmin'))
    
    nd$Time_UTC <- fastPOSIXct(nd$Time_UTC, tz = 'UTC')
    attributes(nd$Time_UTC)$tzone <- 'UTC'
    
    for (i in 2:ncol(nd)) {
      nd[[i]] <- suppressWarnings(as.numeric(nd[[i]]))
    }
    
    nd <- nd %>%
      dplyr::filter(!is.na(Time_UTC), !is.na(O3_ppb)) %>%
      arrange(Time_UTC)
    
    if (nrow(nd) < 1) next
    
    # Initialize qaqc flag
    nd$QAQC_Flag <- 0
    
    # Apply manual qaqc definitions in bad/site/instrument.csv
    nd <- bad_data_fix(nd)
    update_archive(nd, data_path(site, instrument, 'qaqc'))
    update_archive(nd, data_path(site, instrument, 'calibrated'))
  }
})

try({
  # Tank pressure photos
  remote <- paste0('pi@', site_config$ip, ':/home/pi/data/img/')
  local <- file.path('data', site, 'img')
  rsync(from = remote, to = local, port = site_config$port)
})

lock_remove()
