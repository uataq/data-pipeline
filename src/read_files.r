read_files <- function(files, ...) {
  df <- rbindlist(lapply(files, fread, data.table = F, showProgress = F, ...))
  time_col <- grep('time', colnames(df), ignore.case = T, value = T)[1]
  df[[time_col]] <- fastPOSIXct(df[[time_col]], tz = 'UTC')
  return(df)
}
