# James Mineau
# The Raspberry Pi logger running air-trend can lose its time.
# Detecting duplicate times is tricky due to fractional seconds
# and noise in the time resolution.
# Instead, we can detect overlaps by tracking the maximum time seen so far
# and checking if the current time is less than that maximum.
# This will catch cases where the time jumps back. These times can then
# be flagged.
# This method saves half of the duplicated times from being flagged.
# If the time were to errenously jump forward and come back the to real
# time, the real time would be flagged. However, since this is function
# is applied to both the sensor and the gps where ulimately the UTC time
# is pulled, we will still be able to use the data from when the time
# errenously jumped forward. Additionally, as of 2024-04-16, from
# inspection, there are limited number of times when the pi's time
# is more than 10 seconds more than the gps time, indicating this
# rarely happens and has not resulted in overlap.

trax_time_overlap <- function(time) {
  max_so_far <- cummax(time)
  prev_max <- dplyr::lag(max_so_far)
  overlap <- time < prev_max
  overlap[is.na(overlap)] <- FALSE  # First value should be FALSE
  return(overlap)
}