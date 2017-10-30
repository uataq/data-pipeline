lock_remove <- function() {
  lockfile <- paste0('lair-proc/.lock/', site, '.lock')
  system(paste('rm', lockfile))
}