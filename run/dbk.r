# Ben Fasoli

site   <- 'dbk'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta/proc/_global.r')
lock_create()

try({
  
  # Licor 6262 -----------------------------------------------------------------
  instrument <- 'licor_6262'
  proc_init()
  nd <- proc_cr1000()
  update_archive(nd, file.path('data', site, instrument, 'raw/%Y_%m_raw.dat'))
  nd <- licor_6262_qaqc()
  update_archive(nd, file.path('data', site, instrument, 'qaqc/%Y_%m_qaqc.dat'))
  nd <- licor_6262_calibrate()
  update_archive(nd, file.path('data', site, instrument, 'calibrated/%Y_%m_calibrated.dat'))
  
  
  # MetOne ES642 ---------------------------------------------------------------
  site_info[[site]]$reprocess <- T
  instrument <- 'metone_es642'
  proc_init()
  nd <- proc_cr1000()
  update_archive(nd, file.path('data', site, instrument, 'raw/%Y_%m_raw.dat'))
  nd <- metone_es642_qaqc()
  update_archive(nd, file.path('data', site, instrument, 'qaqc/%Y_%m_qaqc.dat'))
  nd <- metone_es642_calibrate()
  update_archive(nd, file.path('data', site, instrument, 'calibrated/%Y_%m_calibrated.dat'))
  
})

lock_remove()
