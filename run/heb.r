# Ben Fasoli

site   <- 'heb'
<<<<<<< HEAD
ip     <- '166.130.69.244'
port   <- 6785
table  <- 'Dat'
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
  # Licor 6262 -----------------------------------------------------------------
  instrument <- 'licor_6262'
  proc_init()
  nd <- cr1000_init()
  if (!site_config$reprocess)
    update_archive(nd, data_path(site, instrument, 'raw'), check_header = F)
  nd <- licor_6262_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- licor_6262_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
})

lock_remove()
>>>>>>> dev
