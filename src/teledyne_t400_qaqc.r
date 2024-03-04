# James Mineau

teledyne_t400_qaqc <- function() {
  # Standardize field names
  colnames(nd) <- data_config[['teledyne_t400']]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Set QAQC Flags
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, O3_ppb < 0 | O3_ppb > 100000 | is.na(O3_ppb))] <- -110
  nd$QAQC_Flag[with(nd, Flow_CCmin < 500 | Flow_CCmin > 1000)] <- -111
  nd$QAQC_Flag[with(nd, Samp_Pres_inHgA < 15 | Samp_Pres_inHgA > 35)] <- -112
  nd$QAQC_Flag[with(nd, Samp_T_C < 10 | Samp_T_C > 50)] <- -113
  nd$QAQC_Flag[with(nd, Box_T_C < 5 | Box_T_C > 50)] <- -114
  nd$QAQC_Flag[filter_warmup(nd, cooldown = '2H', warmup = '1H')] <- -115

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  return(nd)
}
