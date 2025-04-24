get_time_col <- function(nd) {
  time_col <- grep('time', names(nd), ignore.case = T, value = T)[1]
  if (is.na(time_col)) time_col <- 1  # Default to first column
  return(time_col)
}