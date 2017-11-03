get_last_file <- function(path, pattern = '.*\\.{1}dat') {
  lf <- tail(dir(path, pattern = pattern, full.names = T), 1)
  
  if (length(lf) < 1)
    stop('No files found in ', path, ' matching pattern ', pattern)
  
  return(lf)
}