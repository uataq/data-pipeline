# Ben Fasoli

site   <- 'imc'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta/proc/_global.r')
lock_create()

try({
  
  # Licor 6262 -----------------------------------------------------------------
  instrument <- 'licor_6262'
  proc_init()
  nd <- cr1000_init()
  update_archive(nd, file.path('data', site, instrument, 'raw/%Y_%m_raw.dat'))
  nd <- licor_6262_qaqc()
  update_archive(nd, file.path('data', site, instrument, 'qaqc/%Y_%m_qaqc.dat'))
  nd <- licor_6262_calibrate()
  update_archive(nd, file.path('data', site, instrument, 'calibrated/%Y_%m_calibrated.dat'))
  
})

lock_remove()
