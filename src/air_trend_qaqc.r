# James Mineau

air_trend_qaqc <- function() {

  # Standardize column names
  colnames(nd) <- data_config[[instrument]]$qaqc$col_names

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  return(nd)
}