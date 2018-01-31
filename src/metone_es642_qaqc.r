metone_es642_qaqc <- function() {
  
  # Invalidate column containing record number
  nd[, 2] <- NULL
  colnames(nd) <- data_info[[instrument]]$qaqc$col_names[1:ncol(nd)]
  
  # Convert PM2.5 mass concentration from mg m-3 to ug m-3
  nd$PM2.5_ugm3 <- nd$PM2.5_ugm3 * 1000
  
  
  # Initialize qaqc flag
  nd$QAQC_Flag <- 0
  
  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)
  
  # QAQC flag identifiers
  #   1 - Data manually removed
  #   2 - System flush
  #   3 - Invalid valve identifier
  #   4 - Flow rate or cavity pressure out of range
  #   5 - Drift between adjacent reference tank measurements out of range
  #   6 - Time elapsed between reference tank measurements out of range
  #   7 - Reference tank measurements out of range
  nd$QAQC_Flag[with(nd, Flow_Lmin < 1.9 | Flow_Lmin > 2.1)] <- 4
  
  nd
}