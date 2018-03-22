licor_6262_calibrate <- function() {
  
  # Exit if currently sampling reference gases
  if (!site_info[[site]]$reprocess && tail(nd$ID_CO2, 1) != -10) {
    stop('Calibrations disabled. Sampling reference tank at: ', site)
  }
  
  # Import recent data to ensure bracketing reference measurements
  if (!site_info[[site]]$reprocess) {
    # N <- 1 + (as.numeric(format(nd$Time_UTC[1], tz = 'UTC', '%d')) == 1)
    # files <- tail(dir(file.path('data', site, instrument, 'qaqc'),
    #                   pattern = '.*\\.{1}dat', full.names = T), N)
    # nd <- read_files(files, skip = 1,
    #                  col_names = data_info[[instrument]]$qaqc$col_names,
    #                  col_types = data_info[[instrument]]$qaqc$col_types)
    
    fst_file <- file.path('data', site, instrument, 'qaqc.fst')
    con_fst <- fst(fst_file)
    nr <- nrow(con_fst)
    nd <- read_fst(fst_file, from = nr - 10000)
  }
  
  # Invalidate measured mole fraction for records that fail to pass qaqc
  invalid <- c('CO2d_ppm')
  nd[nd$QAQC_Flag %in% 2:4, invalid] <- NA
  
  # Batch calibrate data by year to reduce matrix sizes
  # cal <- with(nd, calibrate_linear(Time_UTC, CO2d_ppm, ID_CO2))
  cal <- nd %>%
    group_by(yyyy = format(Time_UTC, '%Y', tz = 'UTC')) %>%
    do(with(., calibrate_linear(Time_UTC, CO2d_ppm, ID_CO2))) %>%
    ungroup() %>%
    select(-yyyy)
  colnames(cal) <- data_info[[instrument]]$calibrated$col_names
  cal$QAQC_Flag <- ifelse(nd$QAQC_Flag > 0, nd$QAQC_Flag, cal$QAQC_Flag)
  
  if (nrow(cal) != nrow(nd))
    stop('Calibration script returned wrong number of records at: ', site)
  
  last_cal <- with(cal, tail(which(ID_CO2 == -10 & CO2d_n > 0), 1))
  cal[1:last_cal, ]
}