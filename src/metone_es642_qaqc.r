metone_es642_qaqc <- function() {

  # Invalidate column containing record number
  nd[, 2] <- NULL
  colnames(nd) <- data_config[[instrument]]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # QAQC flagging
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  nd$QAQC_Flag[with(nd, Flow_Lmin < 1.9 | Flow_Lmin > 2.1)] <- -4
  nd$QAQC_Flag[with(nd, Cavity_RH_pct < 0 | Cavity_RH_pct > 50)] <- -8

  nd
}
