proc_init <- function() {
  
  invisible(gc())
  
  # Working directory defined as ./site/instrument/(raw,qaqc,calibrated)
  wd <- file.path('data', site, instrument)
  
  # Check if bad data file has been modified since last run
  bad_log_check()
  
  # Check if reprocess flag is TRUE. If site/instrument archive needs to be
  # reprocessed, remove parsed and calibrated data levels
  if (site_info[[site]]$reprocess) {
    message('Reprocessing data archive for: ', site)
    system(paste('rm -r', file.path('data', site, 'hourly')))
    for (path in file.path(wd, c('qaqc', 'calibrated'))) {
      system(paste('rm -r', path))
    }
  }
  
  # Ensure that past processed data exists and set reprocess flag as needed
  for (path in file.path(wd, c('qaqc', 'calibrated'))) {
    if (!file.exists(path) || length(dir(path)) == 0)
      site_info[[site]]$reprocess <<- T
  }
  
  # Check if site is currently active. Exit processing if data is up to date
  if (!site_info[[site]]$reprocess && !site_info[[site]]$is_active) {
    stop(site, ' data already up to date.')
  }
  
  # Ensure directory structure for site/instrument data archive exists
  # for (path in file.path(wd, c('raw', 'qaqc', 'calibrated'))) {
  #   if (!dir.exists(path)) {
  #     message('Path missing. Creating: ', path)
  #     dir.create(path, recursive = T, mode = '0755')
  #   }
  # }
  
}
