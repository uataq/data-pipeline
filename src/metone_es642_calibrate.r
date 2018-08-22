metone_es642_calibrate <- function() {

  # Invalidate measured mass concentration for records that fail to pass qaqc
  invalid <- c('PM2.5_ugm3')
  nd[nd$QAQC_Flag < 0, invalid] <- NA

  # Use qaqc data as "calibrated", or best available data
  cal <- nd
  colnames(cal) <- data_config[[instrument]]$calibrated$col_names

  cal
}
