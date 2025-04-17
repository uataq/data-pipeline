bad_data_fix <- function(data,
                         instrument = get('instrument', envir = globalenv()),
                         site = get('site', envir = globalenv()),
                         site_config = get('site_config', envir = globalenv())) {

  bf <- file.path('pipeline', 'bad', site, paste0(instrument, '.csv'))
  if (!file.exists(bf)) {
    return(data)
  }

  bad_tbl <- read_csv(bf, col_types = 'TTcc___', locale = locale(tz = 'UTC'))

  # Check if the bad data table is empty
  if (nrow(bad_tbl) == 0) return(data)

  # Function to compute mask for a single row of bad_tbl
  compute_mask <- function(bad_row, index) {
    if (grepl('all', bad_row$ID_old, ignore.case = TRUE)) {
      # All data in the time range
      mask <- data$Time_UTC >= bad_row$t_start & data$Time_UTC <= bad_row$t_end
    } else {
      # Data with the same ID in the time range
      mask <- data$Time_UTC >= bad_row$t_start &
              data$Time_UTC <= bad_row$t_end &
              data$ID == bad_row$ID_old
    }
    list(index = index, mask = mask, ID_new = bad_row$ID_new)
  }

  if (site_config$reprocess == TRUE) {
    # Parallelize mask computation
    library(parallel)

    # Use mclapply to compute masks in parallel
    bad_masks <- mclapply(seq_len(nrow(bad_tbl)), function(i) compute_mask(bad_tbl[i, ], i),
                        mc.cores = 10)

    # Sort bad_masks by the original order of bad_tbl
    bad_masks <- bad_masks[order(sapply(bad_masks, function(bad_mask) bad_mask$index))]
  } else {
    # Sequentially compute masks
    bad_masks <- lapply(seq_len(nrow(bad_tbl)), function(i) compute_mask(bad_tbl[i, ], i))
  }

  # Apply bad_masks to data
  for (bad_mask in bad_masks) {
    mask <- bad_mask$mask
    ID_new <- bad_mask$ID_new

    if (is.na(ID_new)) {
      # Set QAQC_Flag to -1 if ID_new is NA (bad data)
      data$QAQC_Flag[mask] <- -1
    } else if (ID_new == 'ok') {
      # Set QAQC_Flag to 1 if ID_new is 'ok'
      data$QAQC_Flag[mask] <- 1
    } else if ('ID' %in% colnames(data)) {
      # Only replace the ID if ID_new is not NA or 'ok'
      # Not all instruments have an ID column (ex: teledynes)
      # For these instruments, the only valid option is ID_old=all & ID_new=NA
      # For instruments with an ID column, replace the ID with the new ID
      data$ID[mask] <- ID_new
    }
  }

  return(data)
}
