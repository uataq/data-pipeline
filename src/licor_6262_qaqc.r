licor_6262_qaqc <- function() {

  # Invalidate columns containing record number and redundant datetime fields
  nd[, 2:7] <- NULL
  colnames(nd) <- data_config[['licor_6262']]$qaqc$col_names[1:ncol(nd)]

  # Filter and sort by time
  nd <- nd %>%
    dplyr::filter(!is.na(Time_UTC)) %>%
    arrange(Time_UTC)

  # Initialize qaqc flag
  nd$QAQC_Flag <- 0

  # Apply manual qaqc definitions in bad/site/instrument.csv
  nd <- bad_data_fix(nd)

  # Extract numeric valve identifier and round result to eliminate precision
  # errors reported by the cr1000
  nd$ID_CO2 <- suppressWarnings(round(as.numeric(nd$ID), 2))

  # Update CO2 values with analog sensor data
  analog_mask <- with(nd, !is.na(CO2_Analog_ppm) &
                        abs(CO2_ppm - CO2_Analog_ppm) > 10 |
                        is.na(CO2_ppm))
  nd$CO2_ppm[analog_mask] <- nd$CO2_Analog_ppm[analog_mask]

  # Compute H2O concentration in ppm
  nd$Cavity_RH_pct <- with(nd, -1.91e-9 * Cavity_RH_mV^3 +
                             1.33e-5 * Cavity_RH_mV^2 +
                             9.56e-3 * Cavity_RH_mV +
                             -21.6)
  nd$Cavity_RH_pct[nd$Cavity_RH_pct > 100] <- 100
  nd$Cavity_RH_pct[nd$Cavity_RH_pct < 0] <- 0
  nd$Cavity_P_Pa <- with(nd, ((Cavity_P_mV/1000) - 0.5) / 4 * 103421)
  nd$H2O_ppm <- with(nd, calc_h2o(RH_pct = Cavity_RH_pct, P_Pa = Cavity_P_Pa,
                                  T_C = Cavity_T_C))

  # Compute dry air CO2 mole fraction estimate by correcting for the dilution
  # effect of H2O on CO2 for atmospheric samples
  nd$CO2d_ppm <- with(nd, calc_h2o_broadening(CO2_ppm, H2O_ppm*10^-6))
  nd$CO2d_ppm <- with(nd, calc_h2o_dilution(CO2d_ppm, H2O_ppm))
  ref_mask <- !is.na(nd$ID_CO2) & nd$ID_CO2 >= 0
  nd$CO2d_ppm[ref_mask] <- nd$CO2_ppm[ref_mask]

  # Fill already-corrected historic SLCCO2 data with NaN in RH column
  dry_mask <- is.na(nd$Cavity_RH_pct)
  nd$CO2d_ppm[dry_mask] <- nd$CO2_ppm[dry_mask]

  # Set QAQC Flags
  # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
  is_manual_pass <- nd$QAQC_Flag == 1
  is_manual_removal <- nd$QAQC_Flag == -1

  nd$QAQC_Flag[analog_mask] <- 2
  nd$QAQC_Flag[with(nd, ID_CO2 == -99)] <- -2
  nd$QAQC_Flag[with(nd, ID_CO2 %in% c(-1, -2, -3, NA))] <- -3
  nd$QAQC_Flag[with(nd, ID_CO2 != -99 & ID_CO2 != -10 & ID_CO2 < 0)] <- -3
  nd$QAQC_Flag[with(nd, CO2d_ppm < 0 | CO2d_ppm > 3000 | is.na(CO2d_ppm))] <- -30
  nd$QAQC_Flag[with(nd, Flow_mLmin < 395 | Flow_mLmin > 405)] <- -31
  nd$QAQC_Flag[with(nd, Cavity_T_C_IRGA < 0 | Cavity_T_C_IRGA > 50)] <- -32
  nd$QAQC_Flag[with(nd, Cavity_P_kPa_IRGA < 75 | Cavity_P_kPa_IRGA > 95)] <- -33
  nd$QAQC_Flag[filter_warmup(nd)] <- -34

  nd$QAQC_Flag[is_manual_pass] <- 1
  nd$QAQC_Flag[is_manual_removal] <- -1

  # Reorder columns
  nd <- nd[, data_config[['licor_6262']]$qaqc$col_names]

  return(nd)
}
