# Ben Fasoli

site   <- 'trx01'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]

lock_create()

if (!site_config$reprocess &&
    !cr1000_is_online(paste(sep=':', site_config$ip, 9191))) {
  lock_remove()
  stop('Unable to connect to ', site_config$ip)
}


### ACTIVE INSTRUMENTS ###

try({
  # GPS ------------------------------------------------------------------------
  instrument <- 'gps'
  proc_init()
  nd <- gps_init()
  nd <- gps_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
})


try({
  # LGR UGGA Manual Calibration ------------------------------------------------
  instrument <- 'lgr_ugga_manual_cal'
  proc_init()
  nd <- air_trend_init(name = 'lgr_ugga')
  nd <- lgr_ugga_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
})


### INACTIVE INSTRUMENTS ###

if (site_config$reprocess) {
  # Only reprocess data if site_config$reprocess is TRUE

try({
  # 2B 205 ---------------------------------------------------------------------
  instrument <- '2b_205'
  proc_init()
  nd <- air_trend_init()
  nd <- bb_205_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
})

try({
  # LGR UGGA -------------------------------------------------------------------
  instrument <- 'lgr_ugga'
  proc_init()
  nd <- air_trend_init()

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
      nd$ID == 'reference'
    nd$ID[mask] <- paste0('~', tank_vals$CO2_ref[i],
                          '~', tank_vals$CH4_ref[i])
  }

  nd <- lgr_ugga_qaqc()

  # trx01 lgr ugga automated qaqc
  nd$QAQC_Flag[with(nd, CO2d_ppm < 300 | CO2d_ppm > 5000)] <- -1
  nd$QAQC_Flag[with(nd, CH4d_ppm < 1 | CH4d_ppm > 100)] <- -1

  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- lgr_ugga_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
})
}



lock_remove()
