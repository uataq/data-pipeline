metone_es642_qaqc <- function(logger = 'cr1000') {

  # Standardize field names
  if (logger == 'cr1000') {
    # CR1000 converts mg/m3 -> ug/m3
    # Invalidate column containing record number
    nd[, 2] <- NULL
  } else if (logger == 'air_trend') {
    # Add cr1000 columns
    nd <- nd %>%
      add_column(batt_volt_Min = NA, PTemp_Avg = NA,
                 .after = 'time') %>%
      mutate(pm25_ugm3 = pm25_mgm3 * 1000) %>%
      select(-pm25_mgm3) %>%
      add_column(Program = 'air-trend')
  }
  colnames(nd) <- data_config[[instrument]]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # QAQC flagging
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  nd$QAQC_Flag[with(nd, Flow_Lmin < 1.9 | Flow_Lmin > 2.1)] <- -4
  nd$QAQC_Flag[with(nd, Cavity_RH_pct < 0 | Cavity_RH_pct > 50)] <- -8

  return(nd)
}
