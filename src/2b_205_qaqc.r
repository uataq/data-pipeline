# James Mineau

bb_205_qaqc <- function() {

  # Standardize field names
  colnames(nd) <- data_config[['2b_205']]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Set QAQC Flags
  is_manual_qc <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, Flow_CCmin < 1950 | Flow_CCmin > 2050)] <- -4

  nd$QAQC_Flag[is_manual_qc] <- -1

  return(nd)
}
