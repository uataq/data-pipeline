read_files <- function(files, ...) {
  df <- rbindlist(lapply(files, fread, ...))
  df$Time_UTC <- fastPOSIXct(df$Time_UTC, tz = 'UTC')
  return(df)
}
