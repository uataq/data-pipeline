# Ben Fasoli

site   <- 'rpk'

message('Run: ', site, ' | ', format(Sys.time(), "%Y-%m-%d %H:%M MTN"))

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]
lock_create()

### Process data for each instrument ###

# Licor 6262 -------------------------------------------------------------------
instrument <- 'licor_6262'
proc_instrument({
  nd <- cr1000_init()
  if (site_config$reprocess == 'FALSE')
    update_archive(nd, data_path(site, instrument, 'raw'), check_header = F)
  nd <- licor_6262_qaqc()
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
  if (site_config$reprocess == 'FALSE')
    update_archive(nd, data_path(site, instrument, 'raw'), check_header = F)
  nd <- licor_7000_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- licor_6262_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})

lock_remove()
