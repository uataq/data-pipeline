# James Mineau

# GPS QC flagging conventions
# 0 : Data passes all QC metrics
# -1 : Data manually removed
# -11 : Poor fix quality

gps_qaqc <- function() {

  # Set column names from data_config
  nd <- nd %>%
    rename(Latitude_deg = latitude_deg,
           Longitude_deg = longitude_deg,
           Altitude_msl = altitude_amsl,
           Speed_kmh = speed_kmh,
           Course_deg = true_course,
           N_Sat = nsat)

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Set QAQC Flags
  is_manual_qc <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[with(nd, !(Fix_Quality %in% c(1, 2)))] <- -11
  nd$QAQC_Flag[with(NSat != as.integer(NSat))] <- -11
  nd$QAQC_Flag[with(nd, NSat < 2)] <- -11
  nd$QAQC_Flag[with(nd, Status != 'A')] <- -11

  nd$QAQC_Flag[is_manual_qc] <- -1

  nd %>%  # update colnames to match data_config
    select(-c(inst_date, inst_time, fix_quality, status))

  nd
}