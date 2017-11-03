lock_create <- function(site = get('site', envir = globalenv()),
                        proc_wd = get('proc_wd', envir = globalenv())) {
  
  lockfile <- file.path(proc_wd, '.lock', paste0(site, '.lock'))
  
  if (file.exists(lockfile))
    stop(paste(site, 'processing running and locked. Exiting...'))
  
  system(paste('touch', lockfile))
}
