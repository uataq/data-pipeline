# James Mineau

site   <- 'ldf'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]

lock_create()


try({
  # LGR UGGA -------------------------------------------------------------------
  instrument <- 'lgr_ugga'
  last_time <- proc_init()
  nd <- air_trend_init()
  nd <- lgr_ugga_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- lgr_ugga_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
})


lock_remove()
