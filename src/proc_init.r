proc_init <- function(site = get('site', envir = globalenv()),
                      instrument = get('instrument', envir = globalenv())) {

  invisible(gc())

  site_inst <- paste(site, instrument, sep = '/')

  # Check if bad data file has been updated since last run
  if (bad_file_updated()) {
    # Add instrument to reprocess list
    if (!should_reprocess()) {
      site_config$reprocess <<- c(instrument)
    } else if (site_config$reprocess != 'TRUE'
               && !instrument %in% unlist(site_config$reprocess)){
      site_config$reprocess <<- c(site_config$reprocess, instrument)
    }
  }

  # Check if processing is disabled
  if (!should_reprocess()) {
    if (!site_config$active) {
      # inactive site
      stop(site_inst, ' data already up to date.')
    } else if (!instrument %in% unlist(site_config$instruments)) {
      # inactive instrument
      stop('Processing disabled for ', site_inst)
    }
  } else if (site_config$reprocess != 'TRUE'
             && !instrument %in% unlist(site_config$reprocess)) {
    # reprocessing disabled for instrument
    stop('Reprocessing disabled for ', site_inst)
  }

  message('Process: ', site_inst, ' | ',
          format(Sys.time(), "%Y-%m-%d %H:%M UTC"))

  # Working directory defined as ./site/instrument/(raw,qaqc,calibrated)
  wd <- file.path('data', site, instrument)

  # Check if reprocess flag is TRUE. If site/instrument archive needs to be
  # reprocessed, remove processed levels
  if (should_reprocess()) {
    message('Reprocessing data archive for: ', site_inst)
    for (path in file.path(wd, c('qaqc', 'calibrated', 'final'))) {
      if (file.exists(path)) {
        message('Removing:', path)
        system(paste('rm -r', path))
      }
    }
  }
}
