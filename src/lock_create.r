lock_create <- function(site) {
  lockfile <- paste0('lair-proc/lock/', site, '.running')
  if (file.exists(lockfile)) stop(paste(site, 'processing already running.'))
  system(paste('touch', lockfile))
}