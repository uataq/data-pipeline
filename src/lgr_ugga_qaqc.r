lgr_ugga_qaqc <- function() {

  # Standardize field names
  colnames(nd) <- data_config[['lgr_ugga']]$qaqc$col_names[1:ncol(nd)]

  # Filter out rows with missing data
  nd <- nd %>%
    dplyr::filter(!is.na(ID), !is.na(CO2d_ppm), !is.na(CH4d_ppm))

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Filter IDs
  atmos_regex <- '^(?=.{5,25}$)(?:V:\\d{1,2}\\s)?~?atmos'  # IDs with "atmos" between 5 & 25 chars
  flush_regex <- '^(?=.{5,15}$)(?:V:\\d{1,2}\\s)?~?flush'  # IDs with "flush" between 5 & 15 chars
  ref_regex <- '^(?:V:\\d{1,2}\\s)?~?(\\d{3}(?:\\.\\d{0,3})?)\\s?(?:~(\\d{1,2}(?:\\.\\d{0,4})?))?'  # regexr.com/7912r

  is.atmos <- grepl(atmos_regex, nd$ID, ignore.case = T, perl = T)
  is.flush <- grepl(flush_regex, nd$ID, ignore.case = T, perl = T)
  is.ref <- grepl(ref_regex, nd$ID) 

  is.bad <- !is.atmos & !is.flush & !is.ref

  # Split CO2 & CH4 IDs
  ID_split <- stringr::str_match(nd$ID, ref_regex)  # Captures CO2 & CH4 groups, returning NA if not found
  suppressWarnings(class(ID_split) <- 'numeric')

  ID_split[is.atmos] <- -10
  ID_split[is.flush] <- -99

  nd$ID_CO2 <- round(ID_split[, 2], 2)
  nd$ID_CH4 <- round(ID_split[, 3], 3)

  # Set QAQC Flags
  is_manual_qc <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[is.flush] <- -2
  nd$QAQC_Flag[is.ref] <- -9
  nd$QAQC_Flag[with(nd, Cavity_P_torr < 135 | Cavity_P_torr > 145)] <- -4
  nd$QAQC_Flag[is.bad] <- -3
  # Not sure the below line is still needed, but keeping just in case - JM
  nd$QAQC_Flag[with(nd, ID_CO2 %in% c(-1, -2, -3, NA) | abs(ID_CO2) < 9)] <- -3

  nd$QAQC_Flag[is_manual_qc] <- -1

  return(nd)
}
