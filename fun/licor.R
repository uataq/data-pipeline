# CO2 site processing script.
# Sourced by SimCity and DoE network processing scripts.
# Ben Fasoli

setwd('/uufs/chpc.utah.edu/common/home/lin-group2/measurements/')
source('lair-proc/global.R')
lock_create()

try({
  # Packages --------------------------------------------------------------------
  lib <- '/uufs/chpc.utah.edu/common/home/u0791983/.Rpackages'
  library(dplyr,   lib.loc=lib)
  library(readr,   lib.loc=lib)
  library(rPython, lib.loc=lib)
  library(uataq,   lib.loc=lib)
  
  # Functions -------------------------------------------------------------------
  get_cr1000 <- function(ip, port, table, site){
    # Collects data from a remote CR1000, using python.    Ben Fasoli
    #     ip           character ip address
    #     port         port number
    #     table        CR1000 table to download
    require(rPython)
    
    lastf <- tail(dir(file.path('data', site, 'raw'), 
                      pattern='.*\\.{1}dat', full.names=T), 1)
    
    if(length(lastf)>0) {
      t_start <- system(paste('tail -n 1', lastf), intern = T) %>% 
        uataq::breakstr() %>% 
        select(1) %>% 
        as.character() %>% 
        as.POSIXct(tz = 'UTC', format = '%Y-%m-%d %H:%M:%S')
      t_start <- as.character(t_start + 1)
      t_end   <- format((Sys.time() + 86400), tz='UTC')
    } else {
      t_start <- ''
      t_end   <- ''
    }
    
    python.load('lair-proc/fun/licor_init.py')
    raw <- python.call('crpull', ip, port, table, t_start, t_end)
    
    if(all(is.null(raw)) | length(raw) < 2) stop('No new data found on logger.')
    
    data <- uataq::breakstr(raw, ncol=21)
    colnames(data) <- c('Time_UTC', 'n', 'Year', 'jDay', 'HH', 'MM', 'SS',
                        'batt_volt', 'PTemp', 'Room_T', 'IRGA_T', 'IRGA_P',
                        'MF_Controller_mLmin', 'PressureVolt', 'rhVolt', 'gas_T',
                        'rawCO2_Voltage', 'rawCO2', 'rawH2O', 'ID', 'Program')
    types <- c('POSIXct', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric',
               'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 
               'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 
               'numeric', 'numeric', 'character')
    for (i in 1:ncol(data)) {
      fun <- switch(types[i],
                    'character' = as.character,
                    'numeric' = as.numeric,
                    'POSIXct' = function(x) {
                      as.POSIXct(x, tz='UTC', format='%Y-%m-%d %H:%M:%S')})
      data[[i]] <- fun(data[[i]])
    }
    
    uataq::archive(data, path=file.path('data', site, 'raw/%Y_%m_raw.dat'))
    return(data)
  }
  
  # Directory structure and data ------------------------------------------------
  if (reset[[site]] | global_reset) {
    system(paste0('rm ', 'data/', site, '/parsed/*')) 
    system(paste0('rm ', 'data/', site, '/calibrated/*'))
    dir.create(file.path('data', site, 'parsed'), 
               showWarnings=FALSE, recursive=TRUE, mode='0755')
    dir.create(file.path('data', site, 'calibrated'), 
               showWarnings=FALSE, recursive=TRUE, mode='0755')
    
    cal_all <- T
    
    raw <- dir(paste0('data/', site, '/raw'), full.names=T) %>%
      lapply(read_csv, locale=locale(tz='UTC'),
             col_names=c('Time_UTC', 'n', 'Year', 'jDay', 'HH', 'MM', 'SS',
                         'batt_volt', 'PTemp', 'Room_T', 'IRGA_T', 'IRGA_P',
                         'MF_Controller_mLmin', 'PressureVolt', 'rhVolt', 
                         'gas_T', 'rawCO2_Voltage', 'rawCO2', 'rawH2O',
                         'ID', 'Program')) %>%
      bind_rows()
    try({raw <- bind_rows(raw, get_cr1000(ip, port, table, site))})
  } else {
    cal_all <- F
    try({raw <- get_cr1000(ip, port, table, site)})
  }
  raw$ID <- round(raw$ID, 2)
  
  # User defined bad data -------------------------------------------------------
  parsed <- remove_bad(raw, site) %>%
    mutate(ID_co2 = ID,
           CO2d_ppm = rawCO2)
  uataq::archive(parsed, path=file.path('data', site, 'parsed/%Y_%m_parsed.dat'))
  
  # Calibrations ----------------------------------------------------------------
  if (!cal_all) {
    files <- tail(dir(file.path('data', site, 'parsed'), full.names=T), 2)
    parsed <- lapply(files, read_csv, locale=locale(tz='UTC')) %>% bind_rows()
  }
  
  cal <- with(parsed, 
              uataq::calibrate(Time_UTC, rawCO2, ID_co2,
                               auto=T, er_tol=0.15, dt_tol=18000)) %>%
    rename(Time_UTC = time,
           CO2d_ppm_cal = cal) %>%
    filter(n > 0)
  
  uataq::archive(cal, path=file.path('data', site, 
                                     'calibrated/%Y_%m_calibrated.dat'))
})
lock_remove()
