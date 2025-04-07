# James Mineau
# Due to floating point errors, keeping accurate microseconds is difficult
# The raw files have different number of decimal places for the microseconds depending on the logger
# Using `format.POSIXct` with "%OS2" does not always return the correct microsecond value
# Instead we will use a custom function to format the time
# There was some discussion around this in 2013: https://stackoverflow.com/questions/7726034/how-r-formats-posixct-with-fractional-seconds
# Warning: I'm not sure if this has been fixed, but issues may arise after 2038: https://stackoverflow.com/a/14720889

format_time <- function(x, tz = 'UTC', format = '%Y-%m-%d %H:%M:%OS2') {
  if (!inherits(x, 'POSIXct'))
    stop('x must be a POSIXct object')

  if (grepl('OS', format)) {
    # Extract the number of digits after the decimal point
    digits <- as.numeric(sub('.*OS', '', format))
    if (is.na(digits))
      digits <- 0

    # Convert to more precise POSIXlt representation
    x2 <- round(unclass(x), digits)  # make sure that all of the units increase appropriately
    attributes(x2) <- attributes(x)
    x <- as.POSIXlt(x2)
    x$sec <- round(x$sec, digits)  # round after converting to the more precise representation

    format.POSIXlt(x, tz = tz, format = format)
  } else {
    # Use the default format
    format.POSIXct(x, tz = tz, format = format)
  }
}
