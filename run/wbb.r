# Ben Fasoli & James Mineau

site   <- 'wbb'
brain <- list(ip = 'uataq-brain.atmosci.utah.edu', port = 22)

# Load settings and initialize lock file
local_time <- format(Sys.time(), '%Y-%m-%d %H:%M %Z')
source('/uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]
lock_create()

message('Run: ', site, ' | ', local_time)

### Process data for each instrument ###

# LGR UGGA ---------------------------------------------------------------------
instrument <- 'lgr_ugga'
proc_instrument({
  nd <- lgr_ugga_init()
  nd <- lgr_ugga_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- lgr_ugga_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# Magee AE33 -------------------------------------------------------------------
instrument <- 'magee_ae33'
proc_instrument({
  nd <- air_trend_init(hostname = brain$ip, port = brain$port)
  nd <- magee_ae33_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# MetOne ES642 -----------------------------------------------------------------
instrument <- 'metone_es642'
proc_instrument({
  nd <- air_trend_init(hostname = brain$ip, port = brain$port)
  nd <- metone_es642_qaqc(logger = 'air_trend')
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# Teledyne T200 ----------------------------------------------------------------
instrument <- 'teledyne_t200'
proc_instrument({
  nd <- air_trend_init(hostname = brain$ip, port = brain$port)
  nd <- teledyne_t200_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# Teledyne T300 ----------------------------------------------------------------
instrument <- 'teledyne_t300'
proc_instrument({
  nd <- air_trend_init(hostname = brain$ip, port = brain$port)
  nd <- teledyne_t300_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# Teledyne T400 ----------------------------------------------------------------
instrument <- 'teledyne_t400'
proc_instrument({
  nd <- air_trend_init(hostname = brain$ip, port = brain$port)
  nd <- teledyne_t400_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# Teledyne T500u ---------------------------------------------------------------
instrument <- 'teledyne_t500u'
proc_instrument({
  nd <- air_trend_init(hostname = brain$ip, port = brain$port)
  nd <- teledyne_t500u_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# TEOM 1400ab ----------------------------------------------------------------
instrument <- 'teom_1400ab'
proc_instrument({
  nd <- air_trend_init(hostname = brain$ip, port = brain$port)
  nd <- teom_1400ab_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

lock_remove()
