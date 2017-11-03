bad_data_fix <- function(data, site = get('site', envir = globalenv()),
                            proc_wd = get('proc_wd', envir = globalenv())) {
  
  bf <- file.path(proc_wd, 'bad', site, 'licor_6262.csv')
  if (!file.exists(bf))
    stop('No bad data file found at ', bf)
  
  bad_tbl <- read_csv(bf, col_types = 'TTcc_', locale = locale(tz = 'UTC'))
  
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