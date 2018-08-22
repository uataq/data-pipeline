# Ben Fasoli

site   <- 'hpl'
<<<<<<< HEAD
ip     <- '69.55.97.79'
=======
>>>>>>> dev

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta/proc/_global.r')
site_config <- site_config[site_config$stid == site, ]
lock_create()

<<<<<<< HEAD
q('no')
=======
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

lock_remove()
>>>>>>> dev
