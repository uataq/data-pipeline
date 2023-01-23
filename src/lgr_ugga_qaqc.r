lgr_ugga_qaqc <- function() {
  
  if (!grepl('trx', site)) {
    # Standardize field names
    colnames(nd) <- data_config[[instrument]]$qaqc$col_names[1:ncol(nd)]
    
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
  nd$ID[nchar(nd$ID) == 0] <- '~-99~-99' # if numChars == 0, its flushing? idk about this
  nd$ID <- gsub('atmosphere', '-10', nd$ID, ignore.case = T)
  nd$ID <- gsub('atmospher', '-10', nd$ID, ignore.case = T)   # deal with potential typo in MIU_DESC
  nd$ID <- gsub('flush', '-99', nd$ID, ignore.case = T)
  nd$ID <- gsub('V:{1}[0-9]{1,2}', '', nd$ID) # remove 2 digit valve identifier
  nd$ID <- gsub('\\s+', '', nd$ID) # remove spaces
  nd$ID <- gsub('^~', '', nd$ID) # remove starting ~
  
  # Remove CO2 only references below threshold (what threshold is BF talking about?)
  mask_no_ch4_ref <- !grepl('~', nd$ID, fixed = T) # if there isnt a '~', then there is no CH4 values
  nd$ID[mask_no_ch4_ref] <- paste0(nd$ID[mask_no_ch4_ref], '~NA') # add '~NA' if there is not a '~'
  
  ID_split <- stringr::str_split_fixed(nd$ID, '~', 2) # causes problems for CH4 when there is more than 1 ~
  suppressWarnings(class(ID_split) <- 'numeric') # converts everything that isnt numeric to NA
  nd$ID_CO2 <- round(ID_split[, 1], 2)
  nd$ID_CH4 <- round(ID_split[, 2], 3)
  
  # QAQC flagging
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_qc <- nd$QAQC_Flag == -1 # set by bad_data_fix
  nd$QAQC_Flag[with(nd, Cavity_P_torr < 135 | Cavity_P_torr > 145)] <- -4
  # I feel like this is a poor way to use the -3 Flag, should be set earlier for things like 'done' or '~'
  # ID = 'NA' should be used for anything other than when the valve is a ref tank
  # Use different flag for when rows are being calibrated, including cal tank rows
  #   How would ID know when rows are being calibrated? Nan can only mean bad MIU_desc
  # we already flag for flushing
  # I don't think we need to explicity identify when it is the atmosphere valve, as that should be covered by the 0 QAQC flag
  #   The only reason I can think of for keeping the -10 identifier is for post QAQC
  #   In either case, filtering for QAQC_Flag == 0 should not return ID_CH4's that are NA or -99 or a positive ID (ref tank)
  # How to flag rows with CO2 ref, but not CH4?
  #   Shouldn't matter? If using co2 ref valve, than cant be measuring CH4.
  #   However, how to measure time between calibrations? 
  #   Should CH4 be nan if too long between tank vals for CH4 but not CO2?
  #   Probably don't have a choice if no CH4 ref is given
  
  nd$QAQC_Flag[with(nd, ID_CO2 %in% c(-1, -2, -3, NA) | abs(ID_CO2) < 9)] <- -3 # why would ID_CO2 have '-1', '-2', or '-3'? also no checks for ch4?
  nd$QAQC_Flag[with(nd, ID_CO2 == -99)] <- -2  #only need to look at CO2
  nd$QAQC_Flag[is_manual_qc] <- -1
  
  nd
}
