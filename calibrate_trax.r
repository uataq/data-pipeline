# LGR Calibration Script
# Filter and calibrate TRAX LGR-UGGA based on raw LGR measurements
# Ben Fasoli

library(parallel)
library(tidyverse)
library(uataq)

cl <- makeForkCluster(24)

old <- '/uufs/chpc.utah.edu/common/home/u0791983/links/lin-group2/trax/TRX01/v1_archive/data/raw/datLgr' %>%
  dir(full.names = T) %>%
  parLapply(cl = cl, read_csv, locale = locale(tz = 'America/Denver'),
            col_types = 'c_T_______d_d_d_d___d_d___',
            col_names = c('valve', 'Time_UTC', 'CH4d_ppm', 'CO2d_ppm',
                          'GasP_torr', 'GasT_C', 'RD0_us', 'RD1_us')) %>%
  bind_rows() %>%
  filter(valve != 'flush')

attributes(old$Time_UTC)$tzone <- 'UTC'

old$valve[old$valve == 'atmos'] <- '-10'
old$valve <- as.numeric(old$valve)
old$valve[old$valve > 0] <- 2
old$valve[old$valve == -10] <- 1
old <- na.omit(old)
attributes(old)$na.action <- NULL

files <- dir('raw/lgr', full.names = T)
raw <- parLapply(cl, files, read_csv, locale = locale(tz = 'UTC'),
                 col_types = 'Ti_______d_d_d_d___d_d___',
                 col_names = c('Time_UTC', 'valve', 'CH4d_ppm', 'CO2d_ppm',
                               'GasP_torr', 'GasT_C', 'RD0_us', 'RD1_us')) %>%
  bind_rows() %>%
  na.omit()

stopCluster(cl)


# ----------------------------------------------------------------------------------------
# Diurnal cycle plotting to investigate timestamp shift
# v1 data should be in local time
# v2 data should be in UTC
# After conversion code, the following diurnal cycles appear CORRECT
# If a time shift still exists, it will stem from either the manipulation (below) or
# the archive function, which could have depreciated dependencies after package updates
# old %>%
#   filter(valve == 1) %>%
#   mutate(delta_co2 = abs(CO2d_ppm - run_smooth(CO2d_ppm, n = 121)),
#          delta_ch4 = abs(CH4d_ppm - run_smooth(CH4d_ppm, n = 121))) %>%
#   filter(GasP_torr > 135, GasP_torr < 145,
#          CO2d_ppm  > 350, CO2d_ppm  < 900,
#          CH4d_ppm  > 1.5, CH4d_ppm  < 100,
#          RD0_us    > 3,   RD0_us    < 15,
#          RD1_us    > 3,   RD1_us    < 15,
#          delta_co2 < quantile(delta_co2, 0.999, na.rm = T),
#          delta_ch4 < quantile(delta_co2, 0.999, na.rm = T)) %>%
#   group_by(Hour = format(Time_UTC, tz = 'America/Denver', '%H') %>% as.numeric()) %>%
#   summarize(CO2 = mean(CO2d_ppm, na.rm = T)) %>%
#   ggplot(aes(x = Hour, y = CO2)) +
#   geom_line()
# 
# raw %>%
#   filter(valve == 1) %>%
#   mutate(delta_co2 = abs(CO2d_ppm - run_smooth(CO2d_ppm, n = 121)),
#          delta_ch4 = abs(CH4d_ppm - run_smooth(CH4d_ppm, n = 121))) %>%
#   filter(GasP_torr > 135, GasP_torr < 145,
#          CO2d_ppm  > 350, CO2d_ppm  < 900,
#          CH4d_ppm  > 1.5, CH4d_ppm  < 100,
#          RD0_us    > 3,   RD0_us    < 15,
#          RD1_us    > 3,   RD1_us    < 15,
#          delta_co2 < quantile(delta_co2, 0.999, na.rm = T),
#          delta_ch4 < quantile(delta_co2, 0.999, na.rm = T)) %>%
#   group_by(Hour = format(Time_UTC, tz = 'America/Denver', '%H') %>% as.numeric()) %>%
#   summarize(CO2 = mean(CO2d_ppm, na.rm = T)) %>%
#   ggplot(aes(x = Hour, y = CO2)) +
#   geom_line()
# 
# filtered %>%
#   # filter(valve == 1) %>%
#   filter(valve == -10) %>%
#   group_by(Hour = format(Time_UTC, tz = 'America/Denver', '%H') %>% as.numeric()) %>%
#   summarize(CO2 = mean(CO2d_ppm, na.rm = T)) %>%
#   ggplot(aes(x = Hour, y = CO2)) +
#   geom_line()
# 
# cal %>%
#   group_by(Hour = format(Time_UTC, tz = 'America/Denver', '%H') %>% as.numeric()) %>%
#   summarize(CO2 = mean(CO2d_ppm_cal, na.rm = T)) %>%
#   ggplot(aes(x = Hour, y = CO2)) +
#   geom_line()
# ----------------------------------------------------------------------------------------

filtered <- bind_rows(old, raw) %>%
  mutate(delta_co2 = abs(CO2d_ppm - run_smooth(CO2d_ppm, n = 121)),
         delta_ch4 = abs(CH4d_ppm - run_smooth(CH4d_ppm, n = 121))) %>%
  filter(valve > 0,
         GasP_torr > 135, GasP_torr < 145,
         CO2d_ppm  > 350, CO2d_ppm  < 1000,
         CH4d_ppm  > 1.5, CH4d_ppm  < 100,
         RD0_us    > 3,   RD0_us    < 15,
         RD1_us    > 3,   RD1_us    < 15,
         delta_co2 < quantile(delta_co2, 0.999, na.rm = T),
         delta_ch4 < quantile(delta_co2, 0.999, na.rm = T)) %>%
  select(Time_UTC, CO2d_ppm, CH4d_ppm, valve)

history <- read_csv('calibrate_trax_tank_history.txt', col_types = 'D_dd',
                    locale = locale(tz = 'UTC', date_format = '%m/%d/%Y'))  %>%
  mutate(start = as.POSIXct(Date),
         end   = c(start[2:n()], Sys.time()))
attributes(history$start)$tzone <- 'UTC'
attributes(history$end)$tzone <- 'UTC'

# Flag atmospheric samples as -10 and reference values with known concentrations
filtered$valve[filtered$valve == 1] <- -10
filtered$ID_co2 <- filtered$valve
filtered$ID_ch4 <- filtered$valve

for (i in 1:nrow(history)) {
  mask <- filtered$Time_UTC >= history$start[i] &
    filtered$Time_UTC < history$end[i] &
    filtered$valve == 2
  filtered$ID_co2[mask] <- history$CO2_ref[i]
  filtered$ID_ch4[mask] <- history$CH4_ref[i]
}

cal <- inner_join(by = 'Time_UTC',
                  calibrate(filtered$Time_UTC, filtered$CO2d_ppm, filtered$ID_co2, er_tol = 0.1, dt_tol = 7200) %>%
                    select(Time_UTC = time, CO2d_ppm_cal = cal, CO2d_ppm_raw = raw, m_co2 = m),
                  calibrate(filtered$Time_UTC, filtered$CH4d_ppm, filtered$ID_ch4, er_tol = 0.1, dt_tol = 7200) %>%
                    select(Time_UTC = time, CH4d_ppm_cal = cal, CH4d_ppm_raw = raw, m_ch4 = m)) %>%
  na.omit()
attributes(cal)$na.action <- NULL

system('rm calibrated/lgr/*')
archive(cal, path = 'calibrated/lgr/%Y-%m.dat')


# cal2 <- dir('calibrated/lgr/', full.names = T) %>%
#   lapply(read_csv, col_types = 'Tdddddd', locale = locale(tz = 'UTC')) %>%
#   bind_rows()
# cal2 %>%
#   group_by(Hour = format(Time_UTC, tz = 'America/Denver', '%H') %>% as.numeric()) %>%
#   summarize(CO2 = mean(CO2d_ppm_cal, na.rm = T)) %>%
#   ggplot(aes(x = Hour, y = CO2)) +
#   geom_line()



