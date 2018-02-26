bad_data_fix <- function(data, 
                         instrument = get('instrument', envir = globalenv()),
                         site = get('site', envir = globalenv())) {
  
  bf <- file.path('proc', 'bad', site, paste0(instrument, '.csv'))
  if (!file.exists(bf)) {
    message('No bad data file found at ', bf)
    return(data)
  }
  
  bad_tbl <- read_csv(bf, col_types = 'TTcc___', locale = locale(tz = 'UTC'))
  
  for (i in 1:nrow(bad_tbl)) {
    if (grepl('all', bad_tbl$miu_old[i], ignore.case = T)) {
      mask <- with(bad_tbl[i, ],
                   data$Time_UTC >= t_start &
                     data$Time_UTC <= t_end)
      data$QAQC_Flag[mask] <- 1
    } else {
      mask <- with(bad_tbl[i, ],
                   data$Time_UTC >= t_start &
                     data$Time_UTC <= t_end &
                     data$ID == miu_old)
    }
    data$ID[mask] <- bad_tbl$miu_new[i]
  }
  return(data)
}
