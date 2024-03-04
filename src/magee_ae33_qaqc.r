# James Mineau

magee_ae33_qaqc <- function() {
  # Standardize field names
  colnames(nd) <- data_config[['magee_ae33']]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Set QAQC Flags
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, BC6_ngm3 < 0 | BC6_ngm3 > 100000 | is.na(BC6_ngm3))] <- -70
  nd$QAQC_Flag[with(nd, Flow_Lmin < 4.9 | Flow_Lmin > 5.1)] <- -71
  nd$QAQC_Flag[filter_warmup(nd)] <- -72

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  return(nd)
}
