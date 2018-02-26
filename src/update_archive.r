update_archive <- function(nd, path = '%Y_%m.dat', tz = 'UTC') {
  
  if (nrow(nd) < 1)
    stop('No new data to append.')
  
  if (!dir.exists(dirname(path)))
    dir.create(dirname(path), recursive = T, mode = '0755')
  
  time_col <- grep('time', names(nd), ignore.case = T, value = T)[1]
  
  nd <- nd[!is.na(nd[[time_col]]), ]
  nd <- nd[order(nd[[time_col]]), ]
  files <- format(nd[[time_col]], tz = tz, format = path)
  
  for (file in (unique(files))) {
    mask <- file == files
    out <- nd[mask, ]
    append <- file.exists(file)
    if (append) {
      hdr <- get_file_header(file)
      if (!all.equal(hdr, colnames(out)))
        stop('Data structure has changed and headers now conflict.')
      out <- out[out[[time_col]] > get_last_time(file), ]
    }
    if (nrow(out) < 1)
      next
    out[[time_col]] <- format(out[[time_col]], tz = tz, '%Y-%m-%dT%H:%M:%OS2')
    write_csv(out, file, append = append)
  }
}
