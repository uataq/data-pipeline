bad_log_check <- function(site = get('site', envir = globalenv()),
                          instrument = get('instrument', envir = globalenv())) {
  
  # Identify bad data file relevant to site/instrument
  badf <- file.path('pipeline', 'bad', site, paste0(instrument, '.csv'))
  
  # Proceed if no bad data file exists
  if (!file.exists(badf)) {
    message('No bad data file found for: ', 
            paste(site, instrument, sep = '/'))
    return()
  }
  
  # Get bad data file last modified time
  mtime <- file.info(badf)$mtime
  attributes(mtime)$tzone <- 'UTC'
  
  # Check if last modified time has changed since last run. Set flag to 
  # reprocess data if bad data file has been modified
  badf_log <- 'pipeline/bad/_log.rds'
  if (!file.exists(badf_log))
    bad_log_init()
  mtime_log <- readRDS(badf_log)
  
  if ((!badf %in% names(mtime_log)) || 
      (trunc(mtime) != trunc(mtime_log[badf]))) {
    mtime_log[badf] <- mtime
    saveRDS(mtime_log, badf_log)
    site_config$reprocess <<- T
  }
}