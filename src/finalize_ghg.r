finalize_ghg <- function() {
  # Reduce dataframe to essential columns and drop QAQC'd rows

  # Define essential columns
  cal_cols <- c('Time_UTC', 'CO2d_ppm_cal', 'CO2d_ppm_meas',
                'CH4d_ppm_cal', 'CH4d_ppm_meas', 'QAQC_Flag', 'ID_CO2')
  qaqc_cols <- c('Time_UTC', 'CH4d_ppm', 'CO2d_ppm', 'H2O_ppm',
                 'QAQC_Flag', 'ID_CO2')

  # Remove CH4 cols
  #  - may need to modify this if new ghg instruments are added
  has_ch4 <- !grepl('licor', instrument)
  if (!has_ch4) {
    cal_cols <- cal_cols[!grepl('CH4', cal_cols)]
    qaqc_cols <- qaqc_cols[!grepl('CH4', qaqc_cols)]
  }

  cal_dir <- file.path('data', site, instrument, 'calibrated')
  qaqc_dir <- file.path('data', site, instrument, 'qaqc')

  # Determine files to read
  months <- unique(format(nd$Time_UTC, '%Y_%m', tz = 'UTC')) %>%
    paste0('.*\\.{1}dat', collapse = '|')

  qaqc_files <- list.files(qaqc_dir, pattern = months, full.names = TRUE)

  if (dir.exists(cal_dir)) {
    # If we have a cal directory, we want the _cal & _meas cols from cal files
    cal_files <- list.files(cal_dir, pattern = months, full.names = TRUE)
    cal <- read_files(cal_files, select = cal_cols)

    # also want the H20_ppm from qaqc files
    # - cal$_meas is the same as qaqc$d_ppm
    # - cal$QAQC_Flag inherited from qaqc$QAQC_Flag
    qaqc <- read_files(qaqc_files, select = c('Time_UTC', 'H2O_ppm'))

    nd <- merge(cal, qaqc, by = 'Time_UTC')
  } else {
    # If we dont have a cal directory, we want the ghg cols from qaqc files
    nd <- read_files(qaqc_files, select = qaqc_cols)

    # Rename to include the _meas suffix
    nd <- nd %>% rename_at(vars(contains('d_ppm')), ~ paste0(., '_meas'))

    # Add _cal columns with NA
    if (has_ch4) {
      nd <- nd %>% mutate(CO2d_ppm_cal = NA, CH4d_ppm_cal = NA)
    } else {
      nd <- nd %>% mutate(CO2d_ppm_cal = NA)
    }
  }

  # Drop QAQC'd rows and reference measurements
  nd <- nd[nd$QAQC_Flag >= 0 & nd$ID_CO2 == -10, ]

  # Set order of columns
  if (grepl('manual_cal', instrument)) {
    # drop _manual_cal from instrument name
    instrument <- gsub('_manual_cal', '', instrument)
  }
  nd <- nd[, data_config[[instrument]]$final$col_names]

  # Round ppms columns
  if (grepl('licor', instrument)) {
    # licors are only good to 1 ppm at best, round to integer
    nd <- nd %>% mutate_at(vars(contains('ppm')), round)
  } else if (grepl('lgr_ugga', instrument)) {
    # lgr ugga is good to 0.5 ppb (4 decimal places) with a 10s measurement
    nd <- nd %>% mutate_at(vars(contains('ppm')), function(x) round(x, 5))
  }

  return(nd)
}
