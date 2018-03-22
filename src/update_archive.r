update_archive <- function(nd, path = '%Y_%m.dat', tz = 'UTC', as_fst = F) {

  if (nrow(nd) < 1)
    stop('No new data to append.')

  if (!dir.exists(dirname(path)))
    dir.create(dirname(path), recursive = T, mode = '0755')

  time_col <- grep('time', names(nd), ignore.case = T, value = T)[1]

  nd <- nd[!is.na(nd[[time_col]]), ]
  nd <- nd[order(nd[[time_col]]), ]
  files <- format(nd[[time_col]], tz = tz, format = path)
  ufiles <- unique(files)
  
  for (file in (ufiles)) {
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
    out[[time_col]] <- format(out[[time_col]], tz = tz, '%Y-%m-%d %H:%M:%OS2')
    write_csv(out, file, append = append)
  }

  if (!as_fst) return()
  invisible(threads_fst(4))
  
  fst_base <- dirname(path)
  fst_dir <- dirname(fst_base)
  fst_file <- file.path(fst_dir, paste0(basename(fst_base), '.fst'))

  if (!file.exists(fst_file)) {
    fst_data <- NULL
  } else {
    fst_data <- read_fst(fst_file)
    nd <- nd[nd$Time_UTC > tail(fst_data$Time_UTC, 1), ]
  }
  fst_data <- bind_rows(fst_data, nd)
  write_fst(fst_data, fst_file, compress = 50)
}
