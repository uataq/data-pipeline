lgr_ugga_qaqc <- function() {

  # Standardize field names
  colnames(nd) <- data_info[[instrument]]$qaqc$col_names[1:ncol(nd)]

  # Timezone America/Denver to UTC shift
  # Data during 12-29-2015 to 12-30-2015 invalid due to shift on day
  nd <- nd  %>%
    filter(Time_UTC < as.POSIXct('2015-12-29', tz = 'UTC') |
            Time_UTC > as.POSIXct('2015-12-30', tz = 'UTC')) %>%
    mutate(pre_utc = Time_UTC < as.POSIXct('2015-12-30', tz = 'UTC'),
           Time_UTC = ifelse(pre_utc,
                             fastPOSIXct(format(Time_UTC, tz = 'UTC'),
                                         tz = 'America/Denver'),
                             Time_UTC))

  # Parse ID column (~CO2~CH4) into ID_CO2 and ID_CH4
  ID_split <- stringr::str_split_fixed(nd$ID, '~', 2)
  ID_split[grepl('atmosphere', ID_split[ ,1], ignore.case = T)] <- '-10'
  ID_split[grepl('flush', ID_split[ ,1], ignore.case = T)]      <- '-99'
  ID_split <- matrix(as.numeric(ID_split), ncol = 2)
  nd$ID_CO2 <- ID_split[, 1]
  nd$ID_CH4 <- ID_split[, 2]

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
  nd$QAQC_Flag[with(nd, Cavity_P_torr < 135 | Cavity_P_torr > 145)] <- 4
  nd$QAQC_Flag[with(nd, ID_CO2 %in% c(-1, -2, -3, NA))] <- 3
  nd$QAQC_Flag[with(nd, ID_CO2 == -99)] <- 2

  nd
}
