# Ben Fasoli
library(dplyr)
library(flexdashboard)
library(ggplot2)
library(readr)
library(rmarkdown)

setwd('/home/benfasoli/cron/air.utah.edu/')

# Dashboard setup --------------------------------------------------------------
sites <- dir('/projects/data') %>%
  grep(pattern = 'trx|csp', x = ., invert = T, value = T)

# Import data ------------------------------------------------------------------
# Fetch parsed and calibrated datasets for all sites over the last two
# calendar months
parsed <- lapply(sites, function(site) {
  inst <- dir(file.path('/projects/data', site))
  col_types <- inst %>%
    (function(x) {
      if ('lgr-ugga' %in% x)
        return('T______d_d_____________cdd')
      else if ('licor-6262' %in% x)
        return('T____________________ddc')
      else
        stop('Improper directory structure found...')
    })
  paths <- file.path('/projects/data', site, inst, 'parsed') %>%
    dir(full.names = T) %>%
    tail(2)
  df <- lapply(paths, read_csv, locale = locale(tz = 'UTC'),
               col_types = col_types, progress = F) %>%
    bind_rows() %>%
    filter(ID_co2 != -1,
           ID_co2 != -2,
           ID_co2 != -3)
  
  if (nrow(df) < 100)
    return(data_frame(site_id = site))
  
  df
}) %>%
  bind_rows()

cal <- lapply(sites, function(site) {
  inst <- dir(file.path('/projects/data', site))
  col_types <- inst %>%
    (function(x) {
      if ('lgr-ugga' %in% x)
        return('Td___d_dd___d_dc')
      else if ('licor-6262' %in% x)
        return('Td___d_dc')
      else
        stop('Improper directory structure found...')
    })
  paths <- file.path('/projects/data', site, inst, 'calibrated') %>%
    dir(full.names = T) %>%
    tail(2)
  
  if (length(paths) < 1)
    return(data_frame(site_id = site))
  
  df <- lapply(paths, read_csv, locale = locale(tz = 'UTC'),
               col_types = col_types, progress = F) %>%
    bind_rows()
  
  if (nrow(df) < 100)
    return(data_frame(site_id = site))
  
  df
}) %>%
  bind_rows()

# Concentration timeseries plots -----------------------------------------------
# Produce concentration timeseries and diurnal cycles
recent <- cal %>%
  rename(Time_Mountain = Time_UTC) %>%
  filter(Time_Mountain >= Sys.time() - 10 * 24 * 3600) %>%
  group_by(site_id,
           Time_Mountain = trunc(Time_Mountain, units = 'hours') %>% 
             as.POSIXct()) %>%
  summarize_each(funs(mean(., na.rm = T)), CO2d_ppm_cal, CH4d_ppm_cal) %>%
  ungroup()

f <- recent %>%
  select(Time_Mountain, CO2d_ppm_cal, site_id) %>%
  na.omit() %>%
  ggplot(aes(x = Time_Mountain, y = CO2d_ppm_cal, color = site_id)) +
  geom_line(alpha = 0.5) +
  xlab(NULL) +
  ylab(NULL) +
  theme_classic() +
  theme(legend.title = element_blank(),
        text = element_text(size = 10))
saveRDS(f, 'data/ts_co2.rds')

f <- recent %>%
  select(Time_Mountain, CH4d_ppm_cal, site_id) %>%
  na.omit() %>%
  ggplot(aes(x = Time_Mountain, y = CH4d_ppm_cal, color = site_id)) +
  geom_line(alpha = 0.5) +
  xlab(NULL) +
  ylab(NULL) +
  theme_classic() +
  theme(legend.title = element_blank(),
        text = element_text(size = 10))
saveRDS(f, 'data/ts_ch4.rds')


# Diurnal cycle plots ----------------------------------------------------------
# Produce concentration timeseries and diurnal cycles
diurnal <- recent %>%
  group_by(site_id,
           Hour = as.numeric(format(Time_Mountain, tz = 'America/Denver',
                                    format = '%H'))) %>%
  summarize_each(funs(mn = mean(., na.rm = T), sd = sd(., na.rm = T)),
                 CO2d_ppm_cal, CH4d_ppm_cal) %>%
  ungroup()

f <- diurnal %>%
  select(Hour, CO2d_ppm_cal_mn, site_id) %>%
  na.omit() %>%
  ggplot(aes(x = Hour, y = CO2d_ppm_cal_mn, color = site_id)) +
  geom_line(alpha = 0.5) +
  xlab(NULL) +
  ylab(NULL) +
  coord_cartesian(ylim = c(380, 500)) +
  theme_classic() +
  theme(legend.title = element_blank(),
        text = element_text(size = 10))
saveRDS(f, 'data/diurnal_co2.rds')

f <- diurnal %>%
  select(Hour, CH4d_ppm_cal_mn, site_id) %>%
  na.omit() %>%
  ggplot(aes(x = Hour, y = CH4d_ppm_cal_mn, color = site_id)) +
  geom_line(alpha = 0.5) +
  xlab(NULL) +
  ylab(NULL) +
  coord_cartesian(ylim = c(1.85, 3)) +
  theme_classic() +
  theme(legend.title = element_blank(),
        text = element_text(size = 10))
saveRDS(f, 'data/diurnal_ch4.rds')

f <- diurnal %>%
  select(Hour, CO2d_ppm_cal_sd, site_id) %>%
  na.omit() %>%
  ggplot(aes(x = Hour, y = CO2d_ppm_cal_sd, color = site_id)) +
  geom_line(alpha = 0.5) +
  xlab(NULL) +
  ylab(NULL) +
  coord_cartesian(ylim = c(0, 60)) +
  theme_classic() +
  theme(legend.title = element_blank(),
        text = element_text(size = 10))
saveRDS(f, 'data/diurnal_co2_sd.rds')

f <- diurnal %>%
  select(Hour, CH4d_ppm_cal_sd, site_id) %>%
  na.omit() %>%
  ggplot(aes(x = Hour, y = CH4d_ppm_cal_sd, color = site_id)) +
  geom_line(alpha = 0.5) +
  xlab(NULL) +
  ylab(NULL) +
  coord_cartesian(ylim = c(0, 1)) +
  theme_classic() +
  theme(legend.title = element_blank(),
        text = element_text(size = 10))
saveRDS(f, 'data/diurnal_ch4_sd.rds')

# Pre-calibration bias plots ---------------------------------------------------
# Subset parsed dataset to produce recent data for calibration offset plots
recent <- parsed %>%
  rename(Time_Mountain = Time_UTC) %>%
  filter(Time_Mountain >= Sys.time() - 7 * 24 * 3600,
         ID_co2 > 0) %>%
  mutate(dCO2d_ppm = CO2d_ppm - ID_co2,
         dCH4d_ppm = CH4d_ppm - ID_ch4) %>%
  group_by(site_id,
           Time_Mountain = trunc(Time_Mountain, units = 'hours') %>% 
             as.POSIXct()) %>%
  summarize_each(funs(mean(., na.rm = T)), dCO2d_ppm, dCH4d_ppm)

f <- ggplot(data = recent,
            aes(x = Time_Mountain, y = dCO2d_ppm, color = site_id)) +
  geom_hline(yintercept = 0, alpha = 0.2, linetype = 'dashed') +
  geom_line() +
  xlab(NULL) +
  ylab(NULL) +
  theme_classic() +
  theme(legend.title = element_blank(),
        text = element_text(size = 10))
saveRDS(f, 'data/cal_offset_co2.rds')

f <- ggplot(data = recent %>% na.omit(),
            aes(x = Time_Mountain, y = dCH4d_ppm, color = site_id)) +
  geom_hline(yintercept = 0, alpha = 0.2, linetype = 'dashed') +
  geom_line() +
  xlab(NULL) +
  ylab(NULL) +
  theme_classic() +
  theme(legend.title = element_blank(),
        text = element_text(size = 10))
saveRDS(f, 'data/cal_offset_ch4.rds')


# RMSE timeseries plots --------------------------------------------------------
# Subset calibrated dataset to produce recent data for RMSE timeseries plots
# n <- 24 * 7 # Hourly resolution
recent <- cal %>%
  rename(Time_Mountain = Time_UTC) %>%
  filter(Time_Mountain >= Sys.time() - 10 * 24 * 3600) %>%
  group_by(site_id,
           Time_Mountain = trunc(Time_Mountain, units = 'hours') %>% 
             as.POSIXct()) %>%
  summarize_each(funs(mean(., na.rm = T)), rmse_co2, rmse_ch4) %>%
  ungroup() %>%
  mutate(rmse_ch4 = rmse_ch4 * 1000)

max_rmse <- 2.0
bad <- recent %>% filter(rmse_co2 > max_rmse)
bad_sites <- unique(bad$site_id)
if (length(bad_sites) > 0) {
  txt <- paste(sep = '\n', collapse = '',
               paste0('RMSE > ', max_rmse, 'ppm: '),
               paste(bad_sites, sep = ', ', collapse = ', '))
} else txt <- ''
f <- ggplot(data = recent,
            aes(x = Time_Mountain, y = rmse_co2, color = site_id)) +
  geom_line() +
  xlab(NULL) +
  ylab(NULL) +
  coord_cartesian(ylim = c(0, max_rmse)) +
  annotate('text', x = Sys.time() - 5 * 24 * 3600,
           y = max_rmse * 0.8, label = txt, size = 3.5) +
  theme_classic() +
  theme(legend.title = element_blank(),
        text = element_text(size = 10))
saveRDS(f, 'data/rmse_co2.rds')

max_rmse <- 10
bad <- recent %>%
  filter(rmse_ch4 > max_rmse)
bad_sites <- unique(bad$site_id)
if (length(bad_sites) > 0) {
  txt <- paste(sep = '\n', collapse = '',
               paste0('RMSE > ', max_rmse, 'ppb: '),
               paste(bad_sites, sep = ', ', collapse = ', '))
} else txt <- ''
f <- ggplot(data = recent %>% na.omit(),
            aes(x = Time_Mountain, y = rmse_ch4, color = site_id)) +
  geom_line() +
  xlab(NULL) +
  ylab(NULL) +
  coord_cartesian(ylim = c(0, max_rmse)) +
  annotate('text', x = Sys.time() - 5 * 24 * 3600,
           y = max_rmse * 0.8, label = txt, size = 3.5) +
  theme_classic() +
  theme(legend.title = element_blank(),
        text = element_text(size = 10))
saveRDS(f, 'data/rmse_ch4.rds')



# Compute site summary statistics ----------------------------------------------
out <- lapply(sites, cal, parsed, FUN = function(site, cal, parsed) {
  parsed <- parsed %>%
    filter(site_id == site,
           Time_UTC >= Sys.time() %>%
             strftime(tz = 'UTC', format = '%Y-%m-01') %>%
             as.POSIXct(tz = 'UTC', format = '%Y-%m-%d'))
  
  tmp <- parsed %>%
    filter(ID_co2 > 0)
  if (nrow(tmp) < 1)
    return(data_frame(site, nsec_smp = 0))
  
  if ('CH4d_ppm' %in% colnames(tmp)) {
    tmp <- tmp %>%
      mutate(diff_co2 = abs(CO2d_ppm - ID_co2),
             diff_ch4 = abs(CH4d_ppm - ID_ch4))
  } else {
    tmp <- tmp %>%
      mutate(diff_co2 = abs(CO2d_ppm - ID_co2),
             diff_ch4 = NA)
  }
  meandiff_co2 <- mean(tmp$diff_co2, na.rm = T)
  meandiff_ch4 <- mean(tmp$diff_ch4, na.rm = T)
  
  # Data recovery rate ---------------------------------------------------------
  # Find elapsed time in raw data since the start of the dataset and compare to
  # the amount of time covered by 10-s calibrated measurements
  nsec_smp <- parsed %>%
    (function(x) {
      len <- nrow(x)
      dt = as.numeric(x$Time_UTC[2:len]) - as.numeric(x$Time_UTC[1:(len-1)])
      # Define observations as having <100 seconds between
      sampling <- dt < 100
      sum(dt[sampling], na.rm = T)
    })
  
  # CALIBRATION TESTING --------------------------------------------------------
  # UATAQ Calibration routine
  # https://github.com/benfasoli/uataq/blob/master/R/calibrate.r
  # Import all calibrated data
  cal <- cal %>%
    filter(site_id == site)
  n_co2 <- tail(cal$n_co2, 1)
  
  # Result output --------------------------------------------------------------
  # Output results to data_frame
  out <- data_frame(
    site,
    nsec_smp,
    n_co2    = n_co2,
    bias_co2 = meandiff_co2,
    rmse_co2 = mean(cal$rmse_co2, na.rm = T)
  )
  if ('rmse_ch4' %in% colnames(cal)) {
    out$bias_ch4 <- meandiff_ch4
    out$rmse_ch4 <- mean(cal$rmse_ch4, na.rm = T)
  }
  out
})

# Aggregate site statistics to total network stats -----------------------------
result <- bind_rows(out) %>%
  mutate(nsec_total = as.numeric(Sys.time()) -
           Sys.time() %>%
           strftime('%Y-%m-01', tz = 'UTC') %>%
           as.POSIXct(tz = 'UTC') %>%
           as.numeric)
result <- bind_rows(result,
                    data_frame(
                      site = 'Total',
                      nsec_smp = sum(result$nsec_smp, na.rm = T),
                      nsec_total = sum(result$nsec_total, na.rm = T),
                      bias_co2 = mean(result$bias_co2, na.rm = T),
                      bias_ch4 = mean(result$bias_ch4, na.rm = T),
                      rmse_co2 = mean(result$rmse_co2, na.rm = T),
                      rmse_ch4 = mean(result$rmse_ch4, na.rm = T)
                    )
) %>%
  mutate(data_recovery_rate = nsec_smp / nsec_total)
saveRDS(result, 'data/stats.rds')


# Compile webpage --------------------------------------------------------------
render_air <- function() {
  # Status page ----------------------------------------------------------------
  tmp_path <- render(input = './_dash_src.Rmd',
                     output_file = './.tmp.html',
                     output_format = flex_dashboard(
                       css = 'styles.css',
                       orientation = 'rows',
                       vertical_layout = 'scroll',
                       includes = includes(
                         in_header = c('_header.html',
                                       '_header_refresher.html'))))
  html <- read_lines(tmp_path)
  system(paste('rm', tmp_path))
  nav  <- read_lines('_navbar.html')
  delete <- c(
    grep('<div class="navbar navbar-inverse navbar-fixed-top" role="navigation">', 
         html, fixed=T),
    grep('</div><!--/.navbar-->', html))
  out <- html[1:(delete[1]-1)]
  out <- append(out, nav)
  out <- append(out, html[(delete[2]+1):length(html)])
  write_lines(out, 'status.html')
  
  # Historic CO2 page ----------------------------------------------------------
  tmp_path <- render(input = './_historic_co2_src.Rmd',
                     output_file = './.tmp.html',
                     output_format = flex_dashboard(
                       css = 'styles.css',
                       orientation = 'rows',
                       vertical_layout = 'scroll',
                       includes = includes(
                         in_header = '_header.html')))
  html <- read_lines(tmp_path)
  system(paste('rm', tmp_path))
  nav  <- read_lines('_navbar.html')
  delete <- c(
    grep('<div class="navbar navbar-inverse navbar-fixed-top" role="navigation">', 
         html, fixed=T),
    grep('</div><!--/.navbar-->', html))
  out <- html[1:(delete[1]-1)]
  out <- append(out, nav)
  out <- append(out, html[(delete[2]+1):length(html)])
  write_lines(out, 'historic_co2.html')
  
  # Render site and clean up ---------------------------------------------------
  rmarkdown::render_site(encoding = 'UTF-8')
  
  system('rm historic_co2.html')
  system('rm status.html')
  system(paste('cp -R _site/* /var/www/air.utah.edu/'))
}

render_air()
