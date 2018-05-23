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
  update_archive(nd, data_path(site, instrument, 'qaqc'))
  nd <- lgr_ugga_calibrate()
  update_archive(nd, data_path(site, instrument, 'calibrated'))
  
  hourly <- nd %>%
    filter(ID_CO2 == -10 | ID_CH4 == -10) %>%
    group_by(Time_UTC = as.POSIXct(trunc(Time_UTC, 'hour'))) %>%
    summarize(CO2d_avg_ppm = mean(CO2d_ppm_cal, na.rm = T),
              CO2d_err_ppm = sd(CO2d_ppm_cal, na.rm = T) + 
                mean(CO2d_rmse, na.rm = T),
              CO2d_n = length(CO2d_ppm_cal[!is.na(CO2d_ppm_cal)]),
              CH4d_avg_ppm = mean(CH4d_ppm_cal, na.rm = T),
              CH4d_err_ppm = sd(CH4d_ppm_cal, na.rm = T) + 
                mean(CH4d_rmse, na.rm = T),
              CH4d_n = length(CH4d_ppm_cal[!is.na(CH4d_ppm_cal)]))
})


# Output hourly aggregated data ----------------------------------------------
if ('hourly' %in% ls() && nrow(hourly) > 0)
  update_archive(hourly, data_path(site, '', 'hourly'))

lock_remove()
