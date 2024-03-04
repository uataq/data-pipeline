proc_init <- function() {

  invisible(gc())

  message('Run: ', site, '/', instrument, ' ', Sys.time())

  # Working directory defined as ./site/instrument/(raw,qaqc,calibrated)
  wd <- file.path('data', site, instrument)

  # Check if bad data file has been modified since last run
  bad_log_check()

  # Check for reprocess file in data/site directory
  reprocess_check()

  # Check if reprocess flag is TRUE. If site/instrument archive needs to be
  # reprocessed, remove processed levels
  if (site_config$reprocess) {
    message('Reprocessing data archive for: ', site, '/', instrument)
    for (path in file.path(wd, c('qaqc', 'calibrated', 'final'))) {
      if (file.exists(path)) {
        message('Removing:', path)
        system(paste('rm -r', path))
      }
    }
  }

  # Check if site is currently active. Exit processing if data is up to date
  if (!site_config$reprocess && !site_config$active) {
    stop(site, ' data already up to date.')
  }
}
