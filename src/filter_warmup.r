filter_warmup <- function(nd, cooldown = '1H', warmup = '5M') {
  # Convert warmup and cooldown to difftime
  to_difftime <- function(x) {
    units <- switch(substr(x, nchar(x), nchar(x)),
                    'H' = 'hours',
                    'M' = 'mins',
                    'S' = 'secs')
    return(as.difftime(as.numeric(substr(x, 1, nchar(x) - 1)), units = units))
  }
  warmup <- to_difftime(warmup)
  cooldown <- to_difftime(cooldown)

  # Calculate the time difference in seconds between consecutive rows
  dt <- as.difftime(c(0, diff(as.numeric(nd$Time_UTC))), units = 'secs')

  # Identify cold starts when the time difference is greater than cooldown
  is_cold <- dt > cooldown

  # Identify the start of each warming period
  on <- nd$Time_UTC[is_cold]

  # Calculate the end of each warming period
  warm <- on + warmup

  # Initialize logical vector to store the rows that are cold
  cold <- rep(FALSE, nrow(nd))

  for (i in seq_along(on)) {
    # Identify the cold rows that are within the current warming period
    warming <- nd$Time_UTC >= on[i] & nd$Time_UTC <= warm[i]
    cold[warming] <- TRUE
  }

  return(cold)
}
