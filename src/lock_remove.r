lock_remove <- function() {
  lockfile <- paste0('lair-proc/lock/', site, '.running')
  system(paste('rm', lockfile))
}