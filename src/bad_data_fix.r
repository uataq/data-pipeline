bad_data_fix <- function(data,
                         instrument = get('instrument', envir = globalenv()),
                         site = get('site', envir = globalenv())) {

  bf <- file.path('pipeline', 'bad', site, paste0(instrument, '.csv'))
  if (!file.exists(bf)) {
    return(data)
  }

  bad_tbl <- read_csv(bf, col_types = 'TTcc___', locale = locale(tz = 'UTC'))

  if (nrow(bad_tbl) == 0) {
    return(data)
  }

  for (i in 1:nrow(bad_tbl)) {
    if (grepl('all', bad_tbl$ID_old[i], ignore.case = T)) {
      mask <- data$Time_UTC >= bad_tbl$t_start[i] &
        data$Time_UTC <= bad_tbl$t_end[i]
    } else {
      mask <- with(bad_tbl[i, ],
                   data$Time_UTC >= t_start &
                     data$Time_UTC <= t_end &
                     data$ID == ID_old)
    }
    data$ID[mask] <- bad_tbl$ID_new[i]
    if (is.na(bad_tbl$ID_new[i])) data$QAQC_Flag[mask] <- -1
  }
  return(data)
}
