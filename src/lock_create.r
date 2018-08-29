lock_create <- function(site = get('site', envir = globalenv())) {
  
  lockfile <- file.path('pipeline', '.lock', paste0(site, '.lock'))
  
  if (file.exists(lockfile)) {
    if (interactive()) {
      stop(paste(site, 'processing running and locked. Exiting...'))
    }
    q('no')
  }
  
  system(paste('touch', lockfile))
}
