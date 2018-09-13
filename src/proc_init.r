proc_init <- function() {

  invisible(gc())

  # Working directory defined as ./site/instrument/(raw,qaqc,calibrated)
  wd <- file.path('data', site, instrument)

  # Check if bad data file has been modified since last run
  bad_log_check()
  
  # Ensure that past processed data exists and set reprocess flag as needed
  for (path in file.path(wd, c('qaqc', 'calibrated'))) {
    if (!file.exists(path) || length(dir(path)) == 0)
      site_config$reprocess <<- T
  }

  # Check if reprocess flag is TRUE. If site/instrument archive needs to be
  # reprocessed, remove parsed and calibrated data levels
  if (site_config$reprocess) {
    message('Reprocessing data archive for: ', site, '/', instrument)
    for (path in file.path(wd, c('qaqc', 'calibrated'))) {
      system(paste('rm -r', path))
    }
  }

  # Check if site is currently active. Exit processing if data is up to date
  if (!site_config$reprocess && !site_config$active) {
    stop(site, ' data already up to date.')
  }

}
