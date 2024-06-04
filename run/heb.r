# Ben Fasoli

site   <- 'heb'

# Load settings and initialize lock file
local_time <- format(Sys.time(), '%Y-%m-%d %H:%M %Z')
source('/uufs/chpc.utah.edu/common/home/lin-group20/measurements/pipeline/_global.r')
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
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- licor_6262_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  nd <- finalize_ghg()
  update_archive(nd, data_path(site, instrument, 'final'))
})

lock_remove()
