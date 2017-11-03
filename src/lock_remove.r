lock_remove <- function(site = get('site', envir = globalenv()),
                        proc_wd = get('proc_wd', envir = globalenv())) {
  lockfile <- file.path(proc_wd, '.lock', paste0(site, '.lock'))
  system(paste('rm', lockfile))
}
