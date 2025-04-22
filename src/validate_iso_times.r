# James Mineau
# The air-trend program used to collect data from serial instruments
# records the raspberry pi's time in ISO 8601 format.
# See github.com/benfasoli/air-trend for Ben's code.
# See my current iteration of the code at github.com/jmineau/air-trend
# Sometimes the pi can lose power and data entries can be corrupted.
# This function drops any rows with invalid ISO 8601 time stamps.

validate_iso_times <- function(.data, time_col = 'time') {
  # ISO 8601 regex pattern with optional fractional seconds
  pattern <- "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?$"

  .data %>%
    dplyr::filter(grepl(pattern, .data[[time_col]]))
}