licor_6262_calibrate <- function() {
  
  # Exit if currently sampling reference gases
  if (tail(nd$ID_CO2, 1) != -10) {
    message('Calibrations disabled. Sampling reference tank at: ', site)
    q('no')
  }
  
  # Import recent data (most recent two files if first day of month) to ensure
  # reference samples bracket new data
  if (site_info[[site]]$reprocess) {
    N <- Inf
  } else {
    N <- 1 + (as.numeric(format(nd$Time_UTC[1], tz = 'UTC', '%d')) == 1)
  }
  files <- tail(dir(file.path('data', site, instrument, 'qaqc'),
                    pattern = '.*\\.{1}dat', full.names = T), N)
  nd <- read_files(files, skip = 1,
                   col_names = data_info[[instrument]]$qaqc$col_names,
                   col_types = data_info[[instrument]]$qaqc$col_types)
  
  # Invalidate measured mole fraction for records that fail to pass qaqc
  nd[nd$QAQC_Flag %in% 2:4, c('CO2d_ppm', 'ID_CO2')] <- NA
  
  cal <- with(nd, calibrate(Time_UTC, CO2d_ppm, ID_CO2))
  colnames(cal) <- data_info[[instrument]]$calibrated$col_names
  cal$QAQC_Flag <- ifelse(nd$QAQC_Flag > 0, nd$QAQC_Flag, cal$QAQC_Flag)
  
  if (nrow(cal) != nrow(nd))
    stop('Calibration script returned wrong number of records at: ', site)
  
  cal
}