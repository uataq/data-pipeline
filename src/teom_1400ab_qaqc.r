# James Mineau

teom_1400ab_qaqc <- function() {
  # Standardize field names
  colnames(nd) <- data_config[['teom_1400ab']]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Set QAQC Flags
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, PM2.5_ugm3 < 0 | PM2.5_ugm3 > 300000 | is.na(PM2.5_ugm3))] <- -130
  nd$QAQC_Flag[filter_warmup(nd)] <- -131

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  return(nd)
}
