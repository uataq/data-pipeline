# Ben Fasoli

site   <- 'trx02'

# Load settings and initialize lock file
local_time <- format(Sys.time(), '%Y-%m-%d %H:%M %Z')
source('/uufs/chpc.utah.edu/common/home/lin-group25/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]
lock_create()

message('Run: ', site, ' | ', local_time)

if (site_config$reprocess == 'FALSE' &&
    !cr1000_is_online(paste(sep=':', site_config$ip, 9191))) {
  lock_remove()
  stop('Unable to connect to ', site_config$ip)
}

### Process data for each instrument ###

# 2B 205 -----------------------------------------------------------------------
instrument <- '2b_205'
proc_instrument({
  nd <- air_trend_init()
  nd <- bb_205_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# GPS --------------------------------------------------------------------------
instrument <- 'gps'
proc_instrument({
  nd <- proc_gps()
  update_archive(nd, data_path(site, instrument, 'qaqc'))

  # Drop QAQC'd rows and reduce dataframe to essential columns
  final_cols <- data_config[['gps']]$final$col_names
  nd <- nd[nd$QAQC_Flag >= 0, final_cols]

  # Round latitude and longitude to 6 decimal places
  nd <- nd %>%
    mutate(Latitude_deg = round(Latitude_deg, 6),
           Longitude_deg = round(Longitude_deg, 6))

  update_archive(nd, data_path(site, instrument, 'final'))
})

# LGR NO2 ----------------------------------------------------------------------
instrument <- 'lgr_no2'
proc_instrument({
  nd <- air_trend_init()
  nd <- lgr_no2_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- nd[nd$ID == -10, ]  # drop reference measurements
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# Met --------------------------------------------------------------------------
instrument <- 'met'  # not really sure which instrument(s) this is
proc_instrument({
  nd <- air_trend_init()
  colnames(nd) <- data_config[[instrument]]$final$col_names
  nd$QAQC_Flag <- 0  # no qaqc flags for met
  nd <- bad_data_fix(nd)
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# MetOne ES642 -----------------------------------------------------------------
instrument <- 'metone_es642'
proc_instrument({
  nd <- air_trend_init()
  nd <- metone_es642_qaqc(logger = 'air_trend')
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

# Teledyne T500u ---------------------------------------------------------------
instrument <- 'teledyne_t500u'
proc_instrument({
  nd <- air_trend_init()
  nd <- teledyne_t500u_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- finalize()
  update_archive(nd, data_path(site, instrument, 'final'))
})

lock_remove()
