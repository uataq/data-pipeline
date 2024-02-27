# Ben Fasoli

site   <- 'trx02'

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
  nd <- proc_gps()
})

try({
  # Teledyne T500u -------------------------------------------------------------
  instrument <- 'teledyne_t500u'
  proc_init()
  nd <- air_trend_init()
  nd <- air_trend_qaqc()
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
  # LGR NO2 --------------------------------------------------------------------
  instrument <- 'lgr_no2'
  proc_init()
  nd <- air_trend_init()
  nd <- air_trend_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
})

try({
  # MetOne ES642 ---------------------------------------------------------------
  instrument <- 'metone_es642'
  proc_init()
  nd <- air_trend_init()
  nd <- metone_es642_qaqc(logger = 'air_trend')
  update_archive(nd, data_path(site, instrument, 'qaqc'))
})
}

lock_remove()
