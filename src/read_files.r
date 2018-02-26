read_files <- function(files, pattern = NULL, col_names = F, ...) {
  return(bind_rows(lapply(files, read_csv, col_names = col_names, 
                          locale = locale(tz = 'UTC'), progress = F, ...)))
}