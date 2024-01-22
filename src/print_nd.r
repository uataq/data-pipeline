print_nd <- function() {
  if (!exists('nd') ||
        nrow(nd) == 0 ||
        !exists('last_time') || 
        last_time == as.POSIXct('1970-01-01', tz = 'UTC')) {
    return()
  }

  new_data <- nd[nd$Time_UTC > last_time, ]
  if (nrow(new_data) > 0) {
    message('New data:')
    str(as.data.frame(new_data))
  }
}
