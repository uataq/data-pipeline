print_nd <- function() {

  # Get nd and last_time from parent frame
  nd <- get('nd', envir = parent.frame())
  last_time <- if(exists('last_time', envir = parent.frame())) {
    get('last_time', envir = parent.frame())
  } else {
    NULL
  }

  # If reprocessing, no prior data, or nd is NULL, don't print anything
  if (is.null(last_time) ||  # reprocessing
        last_time == as.POSIXct('1970-01-01', tz = 'UTC') ||  # no prior data
        is.null(nd) ||
        nrow(nd) == 0) {
    return(invisible())
  }

  time_col <- get_time_col(nd)

  # One line summarizing the new data: how many rows and the time span
  times <- nd[[time_col]][nd[[time_col]] > last_time]
  times <- times[!is.na(times)]
  if (length(times) > 0) {
    message('New data: ', length(times), ' rows, ',
            format(min(times), '%Y-%m-%d %H:%M:%S'), ' to ',
            format(max(times), '%Y-%m-%d %H:%M:%S UTC'))
  } else {
    message('No new data since ', format(last_time, '%Y-%m-%d %H:%M:%S UTC'))
  }
}
