get_last_time <- function(file, timecol = 1, tz = 'UTC', ...) {
  
  if (!file.exists(file))
    stop('File ', file, ' does not exist')

  last <- unlist(strsplit(system(paste('tail -n 1', file), intern = T), ','))
  
  if (length(last) < timecol)
    stop('timecol larger than number of columns in file')
  
  return(as.POSIXct(last[timecol], tz = tz, ...))
}