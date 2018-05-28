# Ben Fasoli

site   <- 'trx01'

# Load settings and initialize lock file
source('/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta/proc/_global.r')
lock_create()

try({
  # LGR UGGA -------------------------------------------------------------------
  instrument <- 'lgr_ugga'
  proc_init()
  # system.time(data <- read_pattern(file.path('data', site, instrument, 'raw', '*.dat'),
  #                      # '1,2,4,6,8,10,12,14,16,18,20,22,23')
  #                      '1,2,4,6,8,10,12,14,16,18,20,22'))
  # files <- dir(file.path('data', site, instrument, 'raw'), '\\.dat$', full.names = T)
  # data <- read_files(files, select = c(1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22))
  
  selector <- file.path('data', site, instrument, 'raw/lgr_2018_02*.dat')
  colnums <- '1,2,4,6,8,10,12,14,16,18,20,22,23'
  # 1s LGR data contains 0 for all standard deviation columns (intended for 
  # longer-term averaged measurements) - drop the extra columns
  pattern <- '-e / -e e' 
  # / : date separator in LGR datetime syntax
  # e : exponent notation in LGR output
  data <- read_pattern(selector, colnums, pattern) %>%
    setNames(c('Time_UTC', 'Valve_ID', 'CH4_ppm', 'H2O_ppm', 'CO2_ppm', 
               'CH4d_ppm', 'CO2d_ppm', 'Cavity_P_torr', 'Cavity_T_C', 'RD0_us', 
               'RD1_us'))
  
  for (i in 2:ncol(data)) {
    data[[i]] <- suppressWarnings(as.numeric(data[[i]]))
  }
  

  # data <- read_pattern(file.path('data', site, instrument, 'raw/*.dat'),
  #                      colnums = '1,2,4,6,8,10,12,14,16,18,20,22',
  #                      pattern = '$')#,
  # select = c(1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22))
  
  nd <- lgr_ugga_init()
  nd <- lgr_ugga_qaqc()
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- lgr_ugga_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
})

lock_remove()
