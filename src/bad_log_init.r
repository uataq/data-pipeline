bad_log_init <- function() {
  badfs <- dir('proc/bad', pattern = 'csv', full.names = T, recursive = T)
  mtimes <- file.info(badfs)$mtime
  attributes(mtimes)$tzone <- 'UTC'
  names(mtimes) <- badfs
  saveRDS(mtimes, 'proc/bad/_log.rds')
}
