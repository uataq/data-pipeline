bad_log_check <- function(site = get('site', envir = globalenv()),
                      proc_wd = get('proc_wd', envir = globalenv())) {
  
  badf <- dir(file.path(proc_wd, 'bad'), pattern = site, full.names = T)
  badf_log <- file.path(proc_wd, 'bad/_log.rds')
  
  mtime <- file.info(badf)$mtime
  attributes(mtime)$tzone <- 'UTC'
  
  mtime_log <- readRDS(badf_log)[site]
  
  if (trunc(mtime) != trunc(mtime_log[site])) {
    mtime_log[site] <- mtime
    saveRDS(mtime_log, badf_log)
    config[[site]]$reset <<- T
  }
}