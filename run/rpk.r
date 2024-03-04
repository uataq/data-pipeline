# Ben Fasoli

site   <- 'rpk'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]
lock_create()


### ACTIVE INSTRUMENTS ###

try({
  # Licor 7000 -----------------------------------------------------------------
  instrument <- 'licor_7000'
  proc_init()
  nd <- cr1000_init()
  if (!site_config$reprocess)
    update_archive(nd, data_path(site, instrument, 'raw'), check_header = F)
  nd <- licor_7000_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  # calibration code for licor_7000 is the same as for licor_6262, so just call licor_6262_calibrate()
  nd <- licor_6262_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})


### INACTIVE INSTRUMENTS ###

if (site_config$reprocess) {
  # Only reprocess data if site_config$reprocess is TRUE

try({
  # Licor 6262 -----------------------------------------------------------------
  instrument <- 'licor_6262'
  proc_init()
  nd <- cr1000_init()
  # if (!site_config$reprocess)
  #     update_archive(nd, data_path(site, instrument, 'raw'), check_header = F)
  nd <- licor_6262_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- licor_6262_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})
}

lock_remove()
