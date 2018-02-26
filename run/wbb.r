# Ben Fasoli

site   <- 'wbb'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta/proc/_global.r')
lock_create()

try({

  # LGR UGGA -------------------------------------------------------------------
  instrument <- 'lgr_ugga'
  proc_init()
  nd <- lgr_ugga_init()
  nd <- lgr_ugga_qaqc()
  update_archive(nd, file.path('data', site, instrument, 'qaqc/%Y_%m_qaqc.dat'))
  nd <- licor_6262_calibrate()
  update_archive(nd, file.path('data', site, instrument, 'calibrated/%Y_%m_calibrated.dat'))

})

lock_remove()
