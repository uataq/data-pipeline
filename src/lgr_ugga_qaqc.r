lgr_ugga_qaqc <- function() {

  # Standardize field names
  colnames(nd) <- data_config[['lgr_ugga']]$qaqc$col_names[1:ncol(nd)]

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Filter IDs
  atmos_regex <- '^(?=.{5,25}$)(?:V:\\d{1,2}\\s)?~?atmos'  # IDs with "atmos" between 5 & 25 chars
  flush_regex <- '^(?=.{5,15}$)(?:V:\\d{1,2}\\s)?~?flush'  # IDs with "flush" between 5 & 15 chars
  ref_regex <- '^(?:V:\\d{1,2}\\s)?~?(\\d{3}(?:\\.\\d{0,3})?)\\s?(?:~(\\d{1,2}(?:\\.\\d{0,4})?))?'  # regexr.com/7912r

  is_atmos <- grepl(atmos_regex, nd$ID, ignore.case = T, perl = T)
  is_flush <- grepl(flush_regex, nd$ID, ignore.case = T, perl = T)
  is_ref <- grepl(ref_regex, nd$ID)

  is_bad <- !is_atmos & !is_flush & !is_ref

  # Split CO2 & CH4 IDs
  ID_split <- stringr::str_match(nd$ID, ref_regex)  # Captures CO2 & CH4 groups, returning NA if not found
  suppressWarnings(class(ID_split) <- 'numeric')

  ID_split[is_atmos] <- -10
  ID_split[is_flush] <- -99

  nd$ID_CO2 <- round(ID_split[, 2], 2)
  nd$ID_CH4 <- round(ID_split[, 3], 3)

  # Set QAQC Flags
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[is_flush] <- -2
  nd$QAQC_Flag[is_bad] <- -3
  nd$QAQC_Flag[with(nd, CH4d_ppm < 0 | CH4d_ppm > 1000 | is.na(CH4d_ppm))] <- -60
  nd$QAQC_Flag[with(nd, CO2d_ppm < 0 | CO2d_ppm > 3000 | is.na(CO2d_ppm))] <- -61
  nd$QAQC_Flag[with(nd, H2O_ppm < 0 | H2O_ppm > 30000)] <- -62
  nd$QAQC_Flag[with(nd, Cavity_P_torr < 135 | Cavity_P_torr > 145)] <- -63
  nd$QAQC_Flag[with(nd, Ambient_T_C < 5 | Ambient_T_C > 45)] <- -64
  nd$QAQC_Flag[filter_warmup(nd)] <- -65

  # Not sure the below line is still needed, but keeping just in case - JM
  nd$QAQC_Flag[with(nd, ID_CO2 %in% c(-1, -2, -3, NA) | abs(ID_CO2) < 9)] <- -3

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  # Reorder columns
  nd <- nd[, data_config[['lgr_ugga']]$qaqc$col_names]

  return(nd)
}
