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

    # Set the QAQC_Flag to 1 if ID_new is 'ok'
    # - Data failed automatic QAQC but manually passed
    if (bad_tbl$ID_new[i] == 'ok') {
      data$QAQC_Flag[mask] <- 1
    } else {  # dont replace ID if ID_new is 'ok'

      if ('ID' %in% colnames(data)) {
        # Not all instruments have an ID column (ex: teledynes)
        # For these instruments, the only valid option is ID_old=all & ID_new=NA
        # For instruments with an ID column, replace the ID with the new ID
        data$ID[mask] <- bad_tbl$ID_new[i]
      }

      # Set the QAQC_Flag to -1 if ID_new is NA (bad data)
      if (is.na(bad_tbl$ID_new[i])) data$QAQC_Flag[mask] <- -1
    }

  }

  return(data)
}
