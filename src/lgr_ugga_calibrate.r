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
  nd <- read_files(file.path('data', site, instrument, 'qaqc'),
                   col_types = data_info[[instrument]]$qaqc$col_types,
                   N = N)
  if (!all.equal(colnames(nd), data_info[[instrument]]$qaqc$col_names))
    stop('Header disagreement between common definition and: ', lf)

  # Invalidate measured mole fraction for records that fail to pass qaqc
  invalid <- c('CO2d_ppm', 'ID_CO2', 'CH4d_ppm', 'ID_CH4')
  nd[nd$QAQC_Flag %in% 2:4, invalid] <- NA

  cal_co2 <- with(nd, calibrate(Time_UTC, CO2d_ppm, ID_CO2))
  cal_ch4 <- with(nd, calibrate(Time_UTC, CH4d_ppm, ID_CH4))
  cal <- cbind(
    cal_co2 %>% select(time, cal, meas, m, b, n, rsq, rmse, id),
    cal_ch4 %>% select(cal, meas, m, b, n, rsq, rmse, id)
  )
  colnames(cal) <- data_info[[instrument]]$calibrated$col_names[1:ncol(cal)]

  # Set QAQC flag giving priority to initial QAQC then calibration QAQC
  cal$QAQC_Flag <- nd$QAQC_Flag
  cal$QAQC_Flag[cal$QAQC_Flag == 0] <- cal_co2$qaqc[cal$QAQC_Flag == 0]
  cal$QAQC_Flag[cal$QAQC_Flag == 0] <- cal_ch4$qaqc[cal$QAQC_Flag == 0]

  if (nrow(cal) != nrow(nd))
    stop('Calibration script returned wrong number of records at: ', site)

  cal
}
