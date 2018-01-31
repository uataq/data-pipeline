metone_es642_calibrate <- function() {
  
  # Invalidate measured mass concentration for records that fail to pass qaqc
  nd[nd$QAQC_Flag %in% 2:4, c('PM2.5_ugm3')] <- NA
  
  # Use qaqc data as "calibrated", or best available data
  cal <- nd
  colnames(cal) <- data_info[[instrument]]$calibrated$col_names
  
  cal
}