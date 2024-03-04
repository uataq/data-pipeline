# James Mineau

teledyne_t300_qaqc <- function() {
  # Standardize field names
  colnames(nd) <- data_config[['teledyne_t300']]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Set QAQC Flags
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, CO_ppb < 0 | CO_ppb > 100000 | is.na(CO_ppb))] <- -100
  nd$QAQC_Flag[with(nd, Flow_CCmin < 500 | Flow_CCmin > 1000)] <- -101
  nd$QAQC_Flag[with(nd, Samp_Pres_inHgA < 15 | Samp_Pres_inHgA > 35)] <- -102
  nd$QAQC_Flag[with(nd, Samp_T_C < 10 | Samp_T_C > 100)] <- -103
  nd$QAQC_Flag[with(nd, Bench_T_C < 46 | Bench_T_C > 50)] <- -104
  nd$QAQC_Flag[with(nd, Wheel_T_C < 66 | Wheel_T_C > 70)] <- -105
  nd$QAQC_Flag[with(nd, Box_T_C < 5 | Box_T_C > 50)] <- -106
  nd$QAQC_Flag[filter_warmup(nd, cooldown = '2H', warmup = '1H')] <- -107

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  return(nd)
}
