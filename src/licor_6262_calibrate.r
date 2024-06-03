licor_6262_calibrate <- function() {

  if (site_config$reprocess == 'FALSE') {
    # Exit if currently sampling reference gases
    if (tail(nd$ID_CO2, 1) != -10)
      stop('Calibrations disabled. Sampling reference tank at: ', site)

    # Import recent data to ensure bracketing reference measurements
    N <- 1 + (as.numeric(format(nd$Time_UTC[1], tz = 'UTC', '%d')) == 1)
    files <- tail(dir(file.path('data', site, instrument, 'qaqc'),
                      pattern = '.*\\.{1}dat', full.names = T), N)
    nd <- read_files(files)
  }

  # Invalidate measured mole fraction for records that fail to pass qaqc,
  #   excluding out of range CO2d values (QAQC_Flag == -30|-40)
  invalid <- c('CO2d_ppm')
  valid_flags <- c(-30, -40)
  nd[with(nd, QAQC_Flag < 0 & !(QAQC_Flag %in% valid_flags)),
     invalid] <- NA

  # Batch calibrate data by year to reduce matrix sizes
  cal <- nd %>%
    group_by(yyyy = format(Time_UTC, '%Y', tz = 'UTC')) %>%
    do(with(., calibrate_linear(Time_UTC, CO2d_ppm, ID_CO2))) %>%
    ungroup() %>%
    select(-yyyy)
  colnames(cal) <- data_config[[instrument]]$calibrated$col_names

  # Set QAQC flag giving priority to calibration QAQC then initial QAQC
  mask <- cal$QAQC_Flag == 0 | is.na(cal$QAQC_Flag)
  cal$QAQC_Flag[mask] <- nd$QAQC_Flag[mask]

  if (nrow(cal) != nrow(nd))
    stop('Calibration script returned wrong number of records at: ', site)

  last_cal <- with(cal, tail(which(ID_CO2 == -10 & CO2d_n > 0), 1))
  if (length(last_cal) == 0) return(cal)
  cal[1:last_cal, ]
}
