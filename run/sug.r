# Ben Fasoli

site   <- 'sug'

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

  # Correct time stamp (erroneously set in MDT) to UTC in Oct 2021
  mask <- nd$Time_UTC > as.POSIXct('2021-10-01 00:00:00', tz = 'UTC') &
          nd$Time_UTC < as.POSIXct('2021-10-19 15:00:00' , tz = 'UTC')
  nd$Time_UTC[mask] <- nd$Time_UTC[mask] + 6*3600 # UTC is 6 hours ahead of MDT

  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- licor_6262_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# Licor 7000 -------------------------------------------------------------------
instrument <- 'licor_7000'
proc_instrument({
  nd <- cr1000_init()
  if (!should_reprocess())
    update_archive(nd, data_path(site, instrument, 'raw'), check_header = F)
  nd <- licor_7000_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- licor_6262_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# MetOne ES642 -----------------------------------------------------------------
instrument <- 'metone_es642'
proc_instrument({
  nd <- cr1000_init()
  if (!should_reprocess())
    update_archive(nd, data_path(site, instrument, 'raw'), check_header = F)
  nd <- metone_es642_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

lock_remove()
