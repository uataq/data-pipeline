# Ben Fasoli

site   <- 'sun'

# Load settings and initialize lock file
local_time <- format(Sys.time(), '%Y-%m-%d %H:%M %Z')
source('/uufs/chpc.utah.edu/common/home/lin-group25/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]
lock_create()

message('Run: ', site, ' | ', local_time)

### Process data for each instrument ###

# Licor 6262 -------------------------------------------------------------------
instrument <- 'licor_6262'
proc_instrument({
  nd <- cr1000_init()
  if (!should_reprocess())
    update_archive(nd, data_path(site, instrument, 'raw'), check_header = F)
  nd <- licor_6262_qaqc()

  # Recalculate dry air CO2 and H2O mole fractions for period with loose RH
  # sensor wire
  mask <- nd$Time_UTC > as.POSIXct('2015-08-31', tz = 'UTC') &
    nd$Time_UTC < as.POSIXct('2015-11-05', tz = 'UTC')
  nd$QAQC_Flag[mask] <- ifelse(nd$QAQC_Flag[mask] < 0, nd$QAQC_Flag[mask], 1)
  nd$H2O_ppm[mask] <- nd$H2O_ppth_IRGA[mask] * 1e3
  nd$CO2d_ppm <- with(nd, calc_h2o_broadening(CO2_ppm, H2O_ppm*10^-6))
  nd$CO2d_ppm <- with(nd, calc_h2o_dilution(CO2d_ppm, H2O_ppm))
  ref_mask <- !is.na(nd$ID_CO2) & nd$ID_CO2 >= 0
  nd$CO2d_ppm[ref_mask] <- nd$CO2_ppm[ref_mask]

  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- licor_6262_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})

lock_remove()
