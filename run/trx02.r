# Ben Fasoli

site   <- 'trx02'

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
  instrument <- 'teledyne_t500u'
  proc_init()
  
  remote <- paste0('pi@', site_config$ip, ':/home/pi/data/teledyne_t500u/')
  local <- file.path('data', site, instrument, 'raw/')
  rsync(from = remote, to = local, port = site_config$port)
})

try({
  # GPS
  instrument <- 'gps'
  proc_init()
  
  remote <- paste0('pi@', site_config$ip, ':/home/pi/data/gps/')
  local <- file.path('data', site, instrument, 'raw/')
  rsync(from = remote, to = local, port = site_config$port)
})


lock_remove()
