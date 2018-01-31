get_last_file <- function(path, pattern = '.*\\.{1}dat', N = 1) {
  lf <- tail(dir(path, pattern = pattern, full.names = T), N)
  
  if (length(lf) < 1) {
    if (interactive())
      message('No files found in ', path, ' matching pattern ', pattern)
    return()
  }
  
  return(lf)
}