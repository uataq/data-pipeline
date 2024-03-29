# James Mineau

bb_205_qaqc <- function() {

  # Standardize field names
  colnames(nd) <- data_config[['2b_205']]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Set QAQC Flags
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, O3_ppb < 0 | O3_ppb > 250 | is.na(O3_ppb))] <- -10
  nd$QAQC_Flag[with(nd, Flow_CCmin < 1800 | Flow_CCmin > 3000)] <- -11
  nd$QAQC_Flag[with(nd, Cavity_T_C < 0 | Cavity_T_C > 50)] <- -12
  nd$QAQC_Flag[filter_warmup(nd)] <- -13

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  return(nd)
}
