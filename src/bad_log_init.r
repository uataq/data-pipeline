bad_log_init <- function() {
  badfs <- dir(file.path(proc_wd, 'bad'), pattern = 'txt', full.names = T)
  mtimes <- file.info(badfs)$mtime
  attributes(mtimes)$tzone <- 'UTC'
  names(mtimes) <- basename(tools::file_path_sans_ext(badfs))
  saveRDS(mtimes, file.path(proc_wd, 'bad/_log.rds'))
}
