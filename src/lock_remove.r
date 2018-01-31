lock_remove <- function(site = get('site', envir = globalenv())) {
  lockfile <- file.path('proc', '.lock', paste0(site, '.lock'))
  
  system(paste('rm', lockfile))
}
