lock_create <- function() {
  if (!site %in% ls())
    stop('"site" not found in global environment')
  lockfile <- paste0('lair-proc/.lock/', site, '.lock')
  if (file.exists(lockfile))
    stop(paste(site, 'processing already running.'))
  system(paste('touch', lockfile))
}