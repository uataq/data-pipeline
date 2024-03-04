# Ben Fasoli & James Mineau

site   <- 'wbb'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline/_global.r')

brain <- site_config[site_config$stid == 'wbb-brain', 'ip']
site_config <- site_config[site_config$stid == site, ]

lock_create()


### ACTIVE INSTRUMENTS ###

try({
  # LGR UGGA -------------------------------------------------------------------
  instrument <- 'lgr_ugga'
  proc_init()
  nd <- lgr_ugga_init()
  nd <- lgr_ugga_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- lgr_ugga_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})

try({
  # Magee AE33 -----------------------------------------------------------------
  instrument <- 'magee_ae33'
  proc_init()
  nd <- air_trend_init(hostname = brain)
  nd <- magee_ae33_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

try({
  # Teledyne T200 --------------------------------------------------------------
  instrument <- 'teledyne_t200'
  proc_init()
  nd <- air_trend_init(hostname = brain)
  nd <- teledyne_t200_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

try({
  # Teledyne T300 --------------------------------------------------------------
  instrument <- 'teledyne_t300'
  proc_init()
  nd <- air_trend_init(hostname = brain)
  nd <- teledyne_t300_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

try({
  # Teledyne T400 --------------------------------------------------------------
  instrument <- 'teledyne_t400'
  proc_init()
  nd <- air_trend_init(hostname = brain)
  nd <- teledyne_t400_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})


### INACTIVE INSTRUMENTS ###

if (site_config$reprocess) {
  # Only reprocess data if site_config$reprocess is TRUE

try({
  # MetOne ES642 ---------------------------------------------------------------
  instrument <- 'metone_es642'
  proc_init()
  nd <- air_trend_init(hostname = brain)
  nd <- metone_es642_qaqc(logger = 'air_trend')
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

try({
  # Teledyne T500u -------------------------------------------------------------
  instrument <- 'teledyne_t500u'
  proc_init()
  nd <- air_trend_init(hostname = brain)
  nd <- teledyne_t500u_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

try({
  # TEOM 1400ab --------------------------------------------------------------
  instrument <- 'teom_1400ab'
  proc_init()
  nd <- air_trend_init(hostname = brain)
  nd <- teom_1400ab_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})
}

lock_remove()
