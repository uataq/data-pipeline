lock_remove <- function(site = get('site', envir = globalenv())) {
  lockfile <- file.path('pipeline', '.lock', paste0(site, '.lock'))
  
  system(paste('rm', lockfile))
}
