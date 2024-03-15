bad_data_fix <- function(data,
                         instrument = get('instrument', envir = globalenv()),
                         site = get('site', envir = globalenv())) {

  bf <- file.path('pipeline', 'bad', site, paste0(instrument, '.csv'))
  if (!file.exists(bf)) {
    return(data)
  }

  bad_tbl <- read_csv(bf, col_types = 'TTcc___', locale = locale(tz = 'UTC'))

  # Check if the bad data table is empty
  if (nrow(bad_tbl) == 0) return(data)

  for (i in 1:nrow(bad_tbl)) {
    # Get the mask for the bad data
    if (grepl('all', bad_tbl$ID_old[i], ignore.case = T)) {
      # all data in the time range
      mask <- data$Time_UTC >= bad_tbl$t_start[i] &
        data$Time_UTC <= bad_tbl$t_end[i]
    } else {
      # data with the same ID in the time range
      mask <- with(bad_tbl[i, ],
                   data$Time_UTC >= t_start &
                     data$Time_UTC <= t_end &
                     data$ID == ID_old)
    }

    # Set QAQC_Flag or ID based on the ID_new column
    if (is.na(bad_tbl$ID_new[i])) {
      # Set the QAQC_Flag to -1 if ID_new is NA (bad data)
      data$QAQC_Flag[mask] <- -1
    } else if (bad_tbl$ID_new[i] == 'ok') {
      # Set the QAQC_Flag to 1 if ID_new is 'ok'
      # - Data failed automatic QAQC but manually passed
      data$QAQC_Flag[mask] <- 1
    } else if ('ID' %in% colnames(data)) { # only replace the ID if ID_new is not NA or 'ok'
      # Not all instruments have an ID column (ex: teledynes)
      # For these instruments, the only valid option is ID_old=all & ID_new=NA
      # For instruments with an ID column, replace the ID with the new ID
      data$ID[mask] <- bad_tbl$ID_new[i]
    }
  }

  return(data)
}
