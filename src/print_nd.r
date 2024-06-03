print_nd <- function() {

  # Get nd and last_time from parent frame
  nd <- get('nd', envir = parent.frame())
  last_time <- if(exists('last_time', envir = parent.frame())) {
    get('last_time', envir = parent.frame())
  } else {
    NULL
  }

  # If no prior data, reprocessing, or nd is NULL, don't print anything
  if (last_time == as.POSIXct('1970-01-01', tz = 'UTC') ||  # no prior data
        is.null(last_time) || # reprocessing
        is.null(nd) ||
        nrow(nd) == 0) {
    return()
  }

  # Print new data
  new_data <- nd[nd$Time_UTC > last_time, ]
  if (nrow(new_data) > 0) {
    # Reserve order so newest data prints first
    new_data <- new_data[order(new_data$Time_UTC, decreasing = T), ]
    message('New data:')
    str(as.data.frame(new_data))
  } else {
    message('No new data found since ', last_time)
  }
}
