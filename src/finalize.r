finalize <- function() {
  # Drop QAQC'd rows and reduce dataframe to essential columns

  # Drop QAQC'd rows
  nd <- nd[nd$QAQC_Flag >= 0, ]

  # Reduce dataframe to essential columns
  final_cols <- data_config[[instrument]]$final$col_names
  nd <- nd[, final_cols]

  return(nd)
}
