# Ben Fasoli

site   <- 'trx01'

# Load settings and initialize lock file
local_time <- format(Sys.time(), '%Y-%m-%d %H:%M %Z')
source('/uufs/chpc.utah.edu/common/home/lin-group25/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]
lock_create()

message('Run: ', site, ' | ', local_time)

if (site_config$reprocess == 'FALSE' &&
    !cr1000_is_online(paste(sep=':', site_config$ip, 9191))) {
  lock_remove()
  stop('Unable to connect to ', site_config$ip)
}

### Process data for each instrument ###

# 2B 205 -----------------------------------------------------------------------
instrument <- '2b_205'
proc_instrument({
  nd <- air_trend_init()
  nd <- bb_205_qaqc()
  nd$QAQC_Flag[trax_time_overlap(nd$Time_UTC)] <- -200  # Remove overlap from pi forgetting time
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# GPS --------------------------------------------------------------------------
instrument <- 'gps'
proc_instrument(proc_gps())

# LGR UGGA ---------------------------------------------------------------------
instrument <- 'lgr_ugga'
proc_instrument({
  nd <- air_trend_init()

  # Apply tank reference values from pipeline/config
  tank_vals <- read_csv('pipeline/config/trx01_tanks.csv',
                        locale = locale(tz = 'UTC', date_format = '%m/%d/%Y'),
                        col_types = 'D_dd') %>%
    mutate(t1 = as.POSIXct(Date),
           t2 = c(t1[2:n()], Sys.time()))

  for (i in c('t1', 't2')) attributes(tank_vals[[i]])$tzone <- 'UTC'
  for (i in 1:nrow(tank_vals)) {
    mask <- nd$time >= tank_vals$t1[i] &
      nd$time < tank_vals$t2[i] &
      nd$ID == 'reference'
    nd$ID[mask] <- paste0('~', tank_vals$CO2_ref[i],
                          '~', tank_vals$CH4_ref[i])
  }

  nd <- lgr_ugga_qaqc()
  nd$QAQC_Flag[trax_time_overlap(nd$Time_UTC)] <- -200  # Remove overlap from pi forgetting time
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- lgr_ugga_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# LGR UGGA Manual Calibration ------------------------------------------------
instrument <- 'lgr_ugga_manual_cal'
proc_instrument({
  nd <- air_trend_init(name = 'lgr_ugga')
  nd <- lgr_ugga_qaqc()
  nd$QAQC_Flag[trax_time_overlap(nd$Time_UTC)] <- -200  # Remove overlap from pi forgetting time
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})

lock_remove()
