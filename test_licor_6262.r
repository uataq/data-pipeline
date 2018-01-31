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

reprocess <- config[[site]]$reset | global_reset

# licor_6262 -----------------------------------------------------------------------------
instrument <- 'licor_6262'
# Check if bad data file has been modified since last run
bad_log_check()

# TODO : temporary
config[[site]]$reset <- TRUE

# Raw ------------------------------------------------------------------------------------
# Fetch data for processing

proc_init()





if (reprocess) {
  # Reset parsed and calibrated datasets
  wd <- file.path(data_wd, site, instrument)
  proc_clean(wd)
  nd <- read_all(file.path(wd, 'raw'),
                 col_names = data_struct[[instrument]]$raw$col_names,
                 col_types = data_struct[[instrument]]$raw$col_types)
} else {
  # Query CR1000 for new records
  lf <- get_last_file(file.path(data_wd, site, instrument, 'raw'))
  lt <- get_last_time(lf)
  lt <- Sys.time() - 48*3600
  nd <- cr1000_query(config[[site]]$ip, 'Dat', lt)
  
  # Clean response data
  nd <- nd[data_struct[[instrument]]$raw$col_names]
  nd$TIMESTAMP <- fastPOSIXct(nd$TIMESTAMP, tz = 'UTC')
  
  if (ncol(nd) != 21)
    stop('Invalid ', table, ' table returned by CR1000 query.')
  
  # update_archive(nd, file.path(data_wd, site, instrument, 'raw/%Y_%m_raw.dat'))
}


# Parsed ---------------------------------------------------------------------------------
nd[ , 2:7] <- NULL
colnames(nd) <- data_struct[[instrument]]$parsed$col_names[1:ncol(nd)]

nd$QAQC_Flag <- 0
nd <- bad_data_fix(nd)
nd$ID_CO2 <- round(as.numeric(nd$ID), 3)

# H2O Sensor Calculations
nd$Cavity_RH_pct <- with(nd, -1.91e-9 * Cavity_RH_mV^3 +
                           1.33e-5 * Cavity_RH_mV^2 +
                           9.56e-3 * Cavity_RH_mV +
                           -21.6)
nd$Cavity_RH_pct[nd$Cavity_RH_pct > 100] <- 100
nd$Cavity_RH_pct[nd$Cavity_RH_pct < 0] <- 0

nd$Cavity_P_Pa <- with(nd, ((Cavity_P_mV/1000) - 0.5) / 4 * 103421)
nd$H2O_ppm <- with(nd, calc_h2o(RH_pct = Cavity_RH_pct, P_Pa = Cavity_P_Pa, 
                                T_C = Cavity_T_C))

# Dilution effect on CO2 for atmospheric samples
nd$CO2d_ppm <- with(nd, calc_h2o_dilution(CO2_ppm, H2O_ppm))
nd$CO2d_ppm <- with(nd, calc_h2o_broadening(CO2d_ppm, H2O_ppm*10^-6))
ref_mask <- !is.na(nd$ID_CO2) & nd$ID_CO2 >= 0
nd$CO2d_ppm[ref_mask] <- nd$CO2_ppm[ref_mask]




# # TODO : Temporary band broadening correction testing
# # CO2dbb_ppm <- calc_h2o_broadening(nd$CO2d_ppm, nd$H2O_ppm * 10^-6)
# Cp <- 421.41
# w <- 3547
# di <- calc_h2o_dilution(Cp, w)
# bb <- calc_h2o_broadening(di, w * 10^-6)
# 
# message('CO2d:       ', bb)
# message('Dilution:   ', di - Cp)
# message('Broadening: ', bb - di)


# di <- with(nd, CO2d_ppm - CO2_ppm)
# bb <- with(nd, CO2dbb_ppm - CO2d_ppm)
# uataq::clc()
# quantile(di, c(0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95), na.rm = T)
# quantile(bb, c(0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95), na.rm = T)




# QAQC Flagging
#    1 - Data manually removed
#    2 - System flush
#    3 - Invalid valve identifier
#    4 - Flow rate or cavity pressure out of range
#    5 - Drift between adjacent reference tank measurements out of range
#    6 - Time elapsed between reference tank measurements out of range
#    7 - Reference tank measurements out of range
nd$QAQC_Flag[with(nd, Flow_mLmin < 395 | Flow_mLmin > 405)] <- 4
nd$QAQC_Flag[with(nd, ID_CO2 %in% c(-1, -2, -3, NA))] <- 3
nd$QAQC_Flag[with(nd, ID_CO2 == -99)] <- 2

# update_archive(nd, file.path(data_wd, site, instrument, 'parsed/%Y_%m_parsed.dat'))


# Calibration ----------------------------------------------------------------------------
# Invalidate QAQC data
nd[nd$QAQC_Flag %in% 2:4, c('CO2d_ppm', 'ID_CO2')] <- NA
nd$ID_CO2 <- round(nd$ID_CO2, 3)
nd$ID_CO2[nd$ID_CO2 == 429.67] <- 429.57

if (tail(nd$ID_CO2, 1) != -10)
  stop('Instrument currently flowing reference. Not calibrating this run.')

cal <- with(nd, calibrate(Time_UTC, CO2d_ppm, ID_CO2))
colnames(cal) <- data_struct[[instrument]]$calibrated$col_names
cal$QAQC_Flag <- ifelse(nd$QAQC_Flag > 0, nd$QAQC_Flag, cal$QAQC_Flag)

# update_archive(cal, file.path(data_wd, site, instrument, 'calibrated/%Y_%m_calibrated.dat'))

# lock_remove()
# q('no')

tmp <- tail(nd, 10000)
cal <- with(tmp, calibrate(Time_UTC, CO2d_ppm, ID_CO2))
colnames(cal) <- data_struct[[instrument]]$calibrated$col_names
cal$QAQC_Flag <- ifelse(tmp$QAQC_Flag > 0, tmp$QAQC_Flag, cal$QAQC_Flag)

tmp <- tail(nd, 10000) %>%
  filter(ID_CO2 != 599.210)
cal2 <- with(tmp, calibrate(Time_UTC, CO2d_ppm, ID_CO2))
colnames(cal2) <- data_struct[[instrument]]$calibrated$col_names
cal2$QAQC_Flag <- ifelse(tmp$QAQC_Flag > 0, tmp$QAQC_Flag, cal$QAQC_Flag)

