metone_es642_qaqc <- function(logger = 'cr1000') {

  # Standardize field names
  if (logger == 'cr1000') {
    # CR1000 converts mg/m3 -> ug/m3
    nd <- nd %>%
      dplyr::filter(!is.na(TIMESTAMP)) %>%
      select(-c(RECORD, batt_volt_Min, PTemp_Avg, Program)) %>%
      add_column(status = NA, .after = 'BP_Avg')
  } else if (logger == 'air_trend') {
    # Add cr1000 columns
    nd <- nd %>%
      mutate(pm25_ugm3 = pm25_mgm3 * 1000) %>%
      select(-pm25_mgm3, -checksum)
  }
  colnames(nd) <- data_config[[instrument]]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # QAQC flagging
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, PM2.5_ugm3 < 0 | PM2.5_ugm3 > 100000 | is.na(PM2.5_ugm3))] <- -80
  nd$QAQC_Flag[with(nd, Flow_Lmin < 1.9 | Flow_Lmin > 2.1)] <- -81
  nd$QAQC_Flag[with(nd, Cavity_RH_pct < 0 | Cavity_RH_pct > 50)] <- -82
  nd$QAQC_Flag[with(nd, Status > 0)] <- -83
  nd$QAQC_Flag[filter_warmup(nd)] <- -84

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  return(nd)
}
