# Ben Fasoli
rm(list = ls())

# Ben Fasoli

# Parameters
site   <- 'lgn'

source('/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta/proc/_config.r')
invisible(source(file.path(proc_wd, '_dependencies.r')))

# Load source code
invisible(lapply(dir(file.path(proc_wd, 'src'), full.names = T), source))
# lock_create()

# Check if bad data file has been modified since last run
bad_log_check()

# licor_6262 -----------------------------------------------------------------------------

# Raw ------------------------------------------------------------------------------------
# Fetch data for processing
if (config[[site]]$reset | global_reset) {
  # Reset parsed and calibrated datasets
  wd <- file.path(data_wd, site, 'licor_6262')
  reset(wd)
  nd <- read_all(file.path(wd, 'raw'),
                 col_names = col_info$licor_6262$raw$col_names,
                 col_types = col_info$licor_6262$raw$col_types)
} else {
  # Query CR1000 for new records
  lf <- get_last_file(file.path(data_wd, site, 'licor-6262', 'raw'))
  lt <- get_last_time(lf)
  lt <- Sys.time() - 15 * 60 # 5*3600
  nd <- cr1000_query(config[[site]]$ip, 'Dat', lt)
  
  # Clean response data
  nd <- nd[col_info$licor_6262$raw$col_names]
  nd$TIMESTAMP <- fastPOSIXct(nd$TIMESTAMP, tz = 'UTC')
  nd$ID <- round(nd$ID, 3)
  
  if (ncol(nd) != 15)
    stop('Invalid ', table, ' table returned by CR1000 query.')
  
  # update_archive(nd, file.path(data_wd, site, 'licor-6262/raw/%Y_%m_raw.dat'))
}


# Parsed ---------------------------------------------------------------------------------
colnames(nd) <- col_info$licor_6262$parsed$col_names


# TODO: bad data file parsing and removal


# H2O Sensor Calculations and Dilution Correction
nd$Cavity_RH_pct <- with(nd, -1.91e-9 * Cavity_RH_mV^3 +
                           1.33e-5 * Cavity_RH_mV^2 +
                           9.56e-3 * Cavity_RH_mV +
                           -21.6)
nd$Cavity_P_Pa <- with(nd, ((Cavity_P_mV / 1000) - 0.5) / 4 * 100000)
nd$H2O_ppm <- with(nd, calc_h2o(RH_pct = Cavity_RH_pct,
                                P_Pa = Cavity_P_Pa,
                                T_C = Cavity_T_C))
nd$H2O_ppm2 <- with(nd, calc_h2o(RH_pct = Cavity_RH_pct,
                                P_Pa = 86000,
                                T_C = Cavity_T_C))
nd$CO2d_ppm <- with(nd, calc_h2o_dilution(CO2_ppm, H2O_ppm))
nd$CO2d_ppm2 <- with(nd, calc_h2o_dilution(CO2_ppm, H2O_ppm2))


# update_archive(nd, file.path(data_wd, site, 'licor-6262/parsed/%Y_%m_parsed.dat'))

# Calibrated -----------------------------------------------------------------------------



# lock_remove()
# q('no')
