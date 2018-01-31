proc_init <- function() {
  
  invisible(gc())
  
  # Working directory defined as ./site/instrument/(raw,qaqc,calibrated)
  wd <- file.path('data', site, instrument)
  
  # Check if bad data file has been modified since last run
  bad_log_check()
  
  # Check if site is currently active. Exit processing if data is up to date
  if (!site_info[[site]]$reprocess && !site_info[[site]]$is_active) {
    q('no')
  }
  
  # Check if reprocess flag is TRUE. If site/instrument archive needs to be
  # reprocessed, remove parsed and calibrated data levels
  if (site_info[[site]]$reprocess) {
    if (interactive())
      message('Reprocessing data archive for: ', site)
    for (path in file.path(wd, c('qaqc', 'calibrated'))) {
      system(paste('rm -r', path))
    }
  }
  
  # Ensure directory structure for site/instrument data archive exists
  for (path in file.path(wd, c('raw', 'qaqc', 'calibrated'))) {
    if (!file.exists(path)) {
      if (interactive())
        message('Path missing. Creating: ', path)
      
      dir.create(path, recursive = T, mode = '0755')
    }
  }
  
}
