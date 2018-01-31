# Ben Fasoli

data_wd <- '/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta/data'
proc_wd <- '/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta/proc'

global_reset <- F

# Site configuration
#  active (logi): site is currently active and should be processed
#  ip (str): IP address of datalogger
#  port (int/str): TCP connection port
#  reset (logi): reprocess site history from raw/ files
#  xyz (numeric): site inlet location, c(long, lati, zagl)
config <- list(
  csp = list(active = F,
             ip     = '69.55.97.78',
             port   = 22,
             reset  = F,
             xyz    = c(-110.0194, 40.050900, 4)),
  dbk = list(active = T,
             ip     = '166.130.22.212',
             port   = 3001,
             reset  = F,
             xyz    = c(-112.069528, 40.538497, 5)),
  fru = list(active = T,
             ip     = '166.130.125.75', 
             port   = 22,
             reset  = F,
             xyz    = c(-110.8403, 40.208731, 4)),
  hdp = list(active = F,
             ip     = '50.224.25.93',
             port   = 22,
             reset  = F,
             xyz    = c(-111.645278, 40.560644, 15)),
  heb = list(active = T,
             ip     = '166.130.69.244', 
             port   = 3001,
             reset  = F,
             xyz    = c(-111.403636, 40.506808, 7)),
  hpl = list(active = T,
             ip     = '166.130.104.236', 
             port   = 22,
             reset  = F,
             xyz    = c(-109.4672, 40.143711, 4)),
  imc = list(active = T,
             ip     = '67.128.146.28',
             port   = 6785,
             reset  = F,
             xyz    = c(-111.89075, 40.660395, 35)),
  lgn = list(active = T,
             ip     = '129.123.46.97',
             port   = 6785,
             reset  = F,
             xyz    = c(-111.822739, 41.761353, 5)),
  roo = list(active = T,
             ip     = '166.130.125.77',
             port   = 22,
             reset  = F,
             xyz    = c(-110.009, 40.294169, 4)),
  rpk = list(active = T,
             ip     = '205.127.188.48',
             port   = 6785,
             reset  = F,
             xyz    = c(-111.931925, 40.794386, 7)),
  sug = list(active = T,
             ip     = '166.130.89.167',
             port   = 3001,
             reset  = F,
             xyz    = c(-111.857831, 40.739906, 10)),
  sun = list(active = T,
             ip     = '107.1.14.185', 
             port   = 6785,
             reset  = F,
             xyz    = c(-111.837047, 40.480978, 5)),
  trx01 = list(active = T,
               ip     = 'uutrax1136.dyndns-remote.com', 
               port   = 8022,
               reset  = F,
               xyz    = c(NA, NA, 5)),
  trx02 = list(active = F,
               ip     = '',
               port   = 22,
               reset  = F,
               xyz    = c(NA, NA, 5)),
  wbb = list(active = T,
             ip     = 'GGA-13-0221.chpc.utah.edu', 
             port   = 22,
             reset  = F,
             xyz    = c(-111.847672, 40.766189, 35))
)


# Data naming and type configuration
data_struct <- list(
  licor_6262 = list(
    raw = list(
      col_names = c('TIMESTAMP', 'RECORD', 'Year', 'jDay', 'HH', 'MM', 'SS',
                    'batt_volt_Min', 'PTemp_Avg', 'Room_T_Avg', 'IRGA_T_Avg',
                    'IRGA_P_Avg', 'MF_Controller_mLmin_Avg', 'PressureVolt_Avg',
                    'RH_voltage_Avg', 'Gas_T_Avg', 'rawCO2_Voltage_Avg', 'rawCO2_Avg',
                    'rawH2O_Avg', 'ID', 'Program'),
      col_types = 'Tdddddddddddddddddddc'),
    parsed = list(
      col_names = c('Time_UTC', 'Battery_Voltage_V', 'Panel_T_C', 'Ambient_T_C', 
                    'Cavity_T_C_IRGA', 'Cavity_P_kPa_IRGA', 'Flow_mLmin', 'Cavity_P_mV',
                    'Cavity_RH_mV', 'Cavity_T_C', 'CO2_Analog_ppm', 'CO2_ppm', 
                    'H2O_ppth_IRGA', 'ID', 'Program', 'QAQC_Flag', 'ID_CO2',
                    'Cavity_RH_pct', 'Cavity_P_Pa', 'H2O_ppm', 'CO2d_ppm'),
      col_types = 'Tdddddddddddddcddddd'),
    calibrated = list(
      col_names = c('Time_UTC', 'CO2d_ppm_cal', 'CO2d_ppm_meas', 'CO2d_m', 'CO2d_b',
                    'CO2d_n', 'CO2d_rsq', 'CO2d_rmse', 'ID_CO2', 'QAQC_Flag'),
      col_types = 'Tddddddd')
  )
)
