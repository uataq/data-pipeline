read_all <- function(path, col_names = F, pattern = NULL, ...) {
  raw_wd <- file.path(wd, 'raw')
  files <- dir(raw_wd, pattern = pattern, full.names = T)
  
  if (length(files) < 1)
    stop('No files found in ', raw_wd)
  
  return(bind_rows(lapply(files, read_csv,
                          col_names = col_names,
                          locale = locale(tz = 'UTC'),
                          ...)))
}