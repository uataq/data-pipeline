read_all <- function(path, pattern = NULL, col_names = F, ...) {
  
  files <- dir(path, pattern = pattern, full.names = T)
  
  if (length(files) < 1)
    stop('No files found in ', path)
  
  return(bind_rows(lapply(files, read_csv, col_names = col_names, 
                          locale = locale(tz = 'UTC'), progress = F, ...)))
}