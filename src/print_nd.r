print_nd <- function() {
  if (!exists('nd') || nrow(nd) == 0) return()

  new_data <- nd[nd$Time_UTC > last_time, ]
  if (nrow(new_data) > 0) {
    message('New data:')
    str(as.data.frame(new_data))
  }
}
