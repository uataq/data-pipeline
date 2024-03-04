# James Mineau

teledyne_t500u <- function() {
  # Standardize field names
  colnames(nd) <- data_config[['teledyne_t500u']]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Set QAQC Flags
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, NO2_ppb < 0 | NO2_ppb > 1000 | is.na(NO2_ppb))] <- -120
  nd$QAQC_Flag[with(nd, Samp_Pres_inHgA < 15 | Samp_Pres_inHgA > 35)] <- -121
  nd$QAQC_Flag[with(nd, Phase_T_C < 15 | Phase_T_C > 35)] <- -122
  nd$QAQC_Flag[with(nd, Box_T_C < 5 | Box_T_C > 50)] <- -123
  nd$QAQC_Flag[with(nd, ARef_L_mm < 400 | ARef_L_mm > 1100)] <- -124
  nd$QAQC_Flag[filter_warmup(nd, cooldown = '2H', warmup = '1H')] <- -125

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  return(nd)
}
