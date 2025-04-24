update_archive <- function(nd, path = '%Y_%m.dat', tz = 'UTC', check_header = T) {

  if (nrow(nd) < 1)
    stop('No new data to append.')

  if (!dir.exists(dirname(path)))
    dir.create(dirname(path), recursive = T, mode = '0755')

  time_col <- get_time_col(nd)

  nd <- nd[!is.na(nd[[time_col]]), ]
  nd <- nd[order(nd[[time_col]]), ]
  nd <- nd[!duplicated(nd[[time_col]]), ]
  files <- format(nd[[time_col]], tz = tz, format = path)
  ufiles <- unique(files)

  for (file in (ufiles)) {
    mask <- file == files
    out <- nd[mask, ]
    append <- file.exists(file)
    if (append) {
      hdr <- get_file_header(file)
      if (check_header && !all(hdr == colnames(out)))
        stop('Data structure has changed and headers now conflict.')
      out <- out[out[[time_col]] > get_last_time(file), ]
    }
    if (nrow(out) < 10)
      next
    out[[time_col]] <- format_time(out[[time_col]])
    fwrite(out, file, append = append, showProgress = F, na = 'NA', quote = F)
  }
}
