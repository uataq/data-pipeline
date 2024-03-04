# James Mineau

lgr_no2_qaqc <- function() {
  # Standardize field names
  nd <- nd %>%
    select(-c(inst_time, Relative_Time_s,
              Valve_Description, Valve_Number, Checksum))

  colnames(nd) <- data_config[['lgr_no2']]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Map IDs
  nd$ID <- dplyr::recode(nd$ID,
                         'Scrubbed Air' = 0,
                         'Sample' = -10,
                         'Discard' = -99,
                         .default = NaN)

  # Set QAQC Flags
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, ID == -99)] <- -2
  nd$QAQC_Flag[with(nd, is.na(ID))] <- -3
  nd$QAQC_Flag[with(nd, NO2_ppb < 0 | NO2_ppb > 1000 | is.na(NO2_ppb))] <- -50
  nd$QAQC_Flag[with(nd, Cavity_P_torr < 296 | Cavity_P_torr > 300)] <- -51
  nd$QAQC_Flag[with(nd, Cavity_T_C < 0 | Cavity_T_C > 50)] <- -52
  nd$QAQC_Flag[filter_warmup(nd)] <- -53

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  return(nd)
}
