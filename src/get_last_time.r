get_last_time <- function(file, header = TRUE, timecol = 1, tz = 'UTC', ...) {

  # Check if file exists
  if (is.null(file) || !file.exists(file) || length(file) == 0) {
    message('No file found for extracting last time at: ', file)
    return(NULL)
  }

  # Check if file has enough lines
  min_lines <- ifelse(header, 2, 1)
  num_lines <- as.numeric(strsplit(system(paste('wc -l', file), intern = T),
                                   ' ')[[1]][1])
  if (num_lines < min_lines) {
    message('File has too few lines for extracting last time: ', file)
    return(NULL)
  }

  # Get last line
  last <- unlist(strsplit(system(paste('tail -n 1', file), intern = T), ','))

  # Check if last line is empty
  if (length(last) == 0) {
    message('No data found for extracting last time at: ', file)
    return(NULL)
  }

  # Check if last line has enough columns
  if (length(last) < timecol)
    stop(paste('timecol larger than number of columns in file:', file))

  # Return last time as POSIXct
  return(as.POSIXct(last[timecol], tz = tz, ...))
}
