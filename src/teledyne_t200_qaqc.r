# James Mineau

teledyne_t200_qaqc <- function() {
  # Standardize field names
  colnames(nd) <- data_config[['teledyne_t200']]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Set QAQC Flags
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, NO_ppb < 0 | NO_ppb > 20000 | is.na(NO_ppb))] <- -90
  nd$QAQC_Flag[with(nd, NO2_ppb < 0 | NO2_ppb > 20000 | is.na(NO2_ppb))] <- -91
  nd$QAQC_Flag[with(nd, Flow_CCmin < 350 | Flow_CCmin > 600)] <- -92
  nd$QAQC_Flag[with(nd, O3_Flow_CCmin < 50 | O3_Flow_CCmin > 150)] <- -93
  nd$QAQC_Flag[with(nd, RCel_Pres_inHgA < 3 | RCel_Pres_inHgA > 6)] <- -94
  nd$QAQC_Flag[with(nd, Moly_T_C < 305 | Moly_T_C > 325)] <- -95
  nd$QAQC_Flag[with(nd, PMT_T_C < 5 | PMT_T_C > 12)] <- -96
  nd$QAQC_Flag[with(nd, Box_T_C < 5 | Box_T_C > 50)] <- -97
  nd$QAQC_Flag[filter_warmup(nd, cooldown = '2H', warmup = '1H')] <- -98

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  return(nd)
}
