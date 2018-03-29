read_files <- function(files, ...) {
  df <- rbindlist(lapply(files, fread, data.table = F, showProgress = F, ...))
  df$Time_UTC <- fastPOSIXct(df$Time_UTC, tz = 'UTC')
  return(df)
}
