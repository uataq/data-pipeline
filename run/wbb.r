# Ben Fasoli

site   <- 'wbb'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group9/measurements/pipeline/_global.r')
site_config <- site_config[site_config$stid == site, ]

lock_create()

try({
  # LGR UGGA -------------------------------------------------------------------
  instrument <- 'lgr_ugga'
  proc_init()
  nd <- lgr_ugga_init()
  nd <- lgr_ugga_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- lgr_ugga_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
})

try({
  # MetOne ES642 ---------------------------------------------------------------
  instrument <- 'metone_es642'
  proc_init()
  remote <- file.path('pi@155.101.8.136:~/data', instrument, '')
  local <- file.path('data', site, instrument, 'raw/')
  if (!site_config$reprocess) {
    rsync(from = remote, to = local)
    selector <- paste(tail(dir(local, full.names = T), 2), collapse = ' ')
  } else {
    selector <- file.path(local, '*')
  }
  colnums <- c(1:6, 8)
  pattern <- '[*]'
  nd <- read_pattern(selector, colnums, pattern) %>%
    add_column(RECORD = NA, batt_volt_Min = NA, PTemp_Avg = NA, .after = 'V1') %>%
    setNames(data_config$metone_es642$raw$col_names) %>%
    mutate_at(vars(PM_25_Avg:BP_Avg), funs(suppressWarnings(as.numeric(.)))) %>%
    mutate(TIMESTAMP = fastPOSIXct(TIMESTAMP, tz = 'UTC'),
           PM_25_Avg = PM_25_Avg * 1000,
           Program = 'uataq-brain')
  nd <- metone_es642_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- metone_es642_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
})

try({
  # Teledyne T200 --------------------------------------------------------------
  instrument <- 'teledyne_t200'
  proc_init()
  remote <- file.path('pi@155.101.8.136:~/data', instrument, '')
  local <- file.path('data', site, instrument, 'raw/')
  # TODO: find workaround for reprocessing flag to still sync
  # if (!site_config$reprocess) {
    rsync(from = remote, to = local)
  # }
})

try({
  # Teledyne T300 --------------------------------------------------------------
  instrument <- 'teledyne_t300'
  proc_init()
  remote <- file.path('pi@155.101.8.136:~/data', instrument, '')
  local <- file.path('data', site, instrument, 'raw/')
  # if (!site_config$reprocess) {
    rsync(from = remote, to = local)
  # }
})

try({
  # Teledyne T400 --------------------------------------------------------------
  instrument <- 'teledyne_t400'
  proc_init()
  remote <- file.path('pi@155.101.8.136:~/data', instrument, '')
  local <- file.path('data', site, instrument, 'raw/')
  # if (!site_config$reprocess) {
    rsync(from = remote, to = local)
  # }
})

try({
  # Teledyne T500u -------------------------------------------------------------
  instrument <- 'teledyne_t500u'
  proc_init()
  remote <- file.path('pi@155.101.8.136:~/data', instrument, '')
  local <- file.path('data', site, instrument, 'raw/')
  # if (!site_config$reprocess) {
  rsync(from = remote, to = local)
  # }
})

try({
  # Magee AE33 -----------------------------------------------------------------
  instrument <- 'magee_ae33'
  proc_init()
  remote <- file.path('pi@155.101.8.136:~/data', instrument, '')
  local <- file.path('data', site, instrument, 'raw/')
  # if (!site_config$reprocess) {
  rsync(from = remote, to = local)
  # }
})

# try({
#   # TEOM 1400ab --------------------------------------------------------------
#   instrument <- 'teom_1400ab'
#   proc_init()
#   remote <- 'uataq@uataq-brain.atmos.utah.edu:~/air-trend/log/data/teom-1400ab/'
#   local <- file.path('data', site, instrument, 'raw/')
#   # if (!site_config$reprocess) {
#     rsync(from = remote, to = local)
#   # }
# })

lock_remove()
