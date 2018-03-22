# Ben Fasoli

site   <- 'roo'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta/proc/_global.r')
lock_create()

try({
  # LGR UGGA -------------------------------------------------------------------
  instrument <- 'lgr_ugga'
  proc_init()
  nd <- lgr_ugga_init()
  nd <- lgr_ugga_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'), as_fst = T)
  nd <- lgr_ugga_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'), as_fst = T)
})

lock_remove()
