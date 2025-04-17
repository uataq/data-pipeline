trax_time_overlap <- function(time) {
  max_so_far <- cummax(time)
  prev_max <- dplyr::lag(max_so_far)
  overlap <- time < prev_max
  overlap[is.na(overlap)] <- FALSE  # First value should be FALSE
  return(overlap)
}