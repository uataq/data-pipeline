get_last_time <- function(file, timecol = 1, tz = 'UTC', ...) {
  
  if (is.null(file) || !file.exists(file)) {
    if (interactive())
      message('No file found for extracting last time')
    return(as.POSIXct(0, tz = 'UTC', origin = '1970-01-01'))
  }

  last <- unlist(strsplit(system(paste('tail -n 1', file), intern = T), ','))
  
  if (length(last) < timecol)
    stop('timecol larger than number of columns in file')
  
  return(as.POSIXct(last[timecol], tz = tz, ...))
}