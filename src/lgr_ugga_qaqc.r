lgr_ugga_qaqc <- function() {
  
  if (!grepl('trx', site)) {
    # Standardize field names
    colnames(nd) <- data_info[[instrument]]$qaqc$col_names[1:ncol(nd)]
    
    # Timezone America/Denver to UTC shift
    # Data during 12-29-2015 to 12-30-2015 invalid due to shift on day
    nd <- nd  %>%
      filter(Time_UTC < as.POSIXct('2015-12-29', tz = 'UTC') |
               Time_UTC > as.POSIXct('2015-12-30', tz = 'UTC')) %>%
      mutate(Time_UTC = ifelse(Time_UTC < as.POSIXct('2015-12-30', tz = 'UTC'),
                               as.POSIXct(format(Time_UTC, tz = 'UTC'),
                                          tz = 'America/Denver'),
                               Time_UTC))
    attributes(nd$Time_UTC) <- list(
      class = c('POSIXct', 'POSIXt'),
      tzone = 'UTC'
    )
  }
  
  # Initialize qaqc flag
  nd$QAQC_Flag <- 0
  
  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)
  
  # Parse ID column (~CO2~CH4) into ID_CO2 and ID_CH4
  nd$ID <- gsub('atmosphere', '-10', nd$ID, ignore.case = T)
  nd$ID <- gsub('flush', '-99', nd$ID, ignore.case = T)
  nd$ID <- gsub('V:{1}[0-9]', '', nd$ID)
  nd$ID <- gsub('\\s+', '', nd$ID)
  nd$ID <- gsub('^~', '', nd$ID)
  
  # Remove CO2 only references below threshold
  mask_no_ch4_ref <- !grepl('~', nd$ID, fixed = T)
  nd$ID[mask_no_ch4_ref] <- paste0(nd$ID[mask_no_ch4_ref], '~NA')
  
  ID_split <- stringr::str_split_fixed(nd$ID, '~', 2)
  suppressWarnings(class(ID_split) <- 'numeric')
  nd$ID_CO2 <- round(ID_split[, 1], 2)
  nd$ID_CH4 <- round(ID_split[, 2], 3)
  
  # QAQC flag identifiers
  # -1 - Data manually removed
  # -2 - System flush
  # -3 - Invalid valve identifier
  # -4 - Flow rate or cavity pressure out of range
  # -5 - Drift between adjacent reference tank measurements out of range
  # -6 - Time elapsed between reference tank measurements out of range
  # -7 - Reference tank measurements out of range
  # 1 - Measurement data filled from backup data recording source
  nd$QAQC_Flag[with(nd, Cavity_P_torr < 135 | Cavity_P_torr > 145)] <- -4
  nd$QAQC_Flag[with(nd, 
                    ID_CO2 %in% c(-1, -2, -3, NA) | abs(ID_CO2) < 9)] <- -3
  nd$QAQC_Flag[with(nd, ID_CO2 == -99)] <- -2
  
  nd
}
