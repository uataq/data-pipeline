# LGR site processing script.
# Sourced by Uinta Basin and WBB processing scripts.
# Ben Fasoli

setwd('/uufs/chpc.utah.edu/common/home/lin-group2/measurements/')
source('proc/global.R')

# Packages --------------------------------------------------------------------
lib <- '/uufs/chpc.utah.edu/common/home/u0791983/.Rpackages'
library(dplyr,   lib.loc=lib)
library(readr,   lib.loc=lib)
library(uataq,   lib.loc=lib)

# Functions -------------------------------------------------------------------
pull_lgr <- function(ip, site) {
  cmd <- paste0('/usr/bin/rsync -vrutzhO --stats --exclude="archive/" -e ',
                '"/usr/bin/ssh -i /uufs/chpc.utah.edu/common/home/u0791983/.ssh/id_rsa" ',
                'lgr@', ip, ':/home/lgr/data/ ',
                '/uufs/chpc.utah.edu/common/home/lin-group2/measurements/data/', site, '/raw/')
  system(cmd)
}


# Directory structure and data ------------------------------------------------
pull_lgr(ip, site)

if (reset[[site]] | global_reset) {
  system(paste0('rm ', 'data/', site, '/parsed/*')) 
  system(paste0('rm ', 'data/', site, '/calibrated/*'))
  dir.create(file.path('data', site, 'parsed'), 
             showWarnings=FALSE, recursive=TRUE, mode='0755')
  dir.create(file.path('data', site, 'calibrated'), 
             showWarnings=FALSE, recursive=TRUE, mode='0755')
  
  cal_all <- T
} else {
  cal_all <- F
}

# Determine files to be read --------------------------------------------------
# Unzip necessary compressed data packets
dir('data/wbb/raw', '\\.{1}zip', full.names=T, recursive=T) %>%
  lapply(function(zf) {
    tf <- tools::file_path_sans_ext(zf)
    if (file.exists(tf) && round(file.mtime(zf))==round(file.mtime(tf))) {
      return(NULL)
    } else {
      # If the ASCII .txt file does not exist or the modified time does not
      # match that of the .zip file, overwrite the text file with data from the
      # .zip file and update the modified times of the two
      system(paste('unzip', zf, '-d', dirname(zf)))
      system(paste('touch', zf, tf))
    }
  })

tfs <- dir('data/wbb/raw', 'f....\\.{1}txt$', full.names=T, recursive=T)
if (!cal_all) tfs <- tail(tfs, 2)


# TEMP
tfs <- "data/wbb/raw/14Mar2016/gga14Mar2016_f0000.txt"


# Read files ------------------------------------------------------------------
raw <- lapply(tfs, function(tf) {
  df <- tryCatch(suppressWarnings(
    read_csv(tf, col_names=F, skip=2, na=c('TO', '', 'NA'), 
             locale=locale(tz='UTC'))),
    error=function(e){NULL})
  # Adapt column names depending on LGR software version.
  #  2013-2014 version has 23 columns.
  #  2014+ version has 24 columns (MIU split into valve and description).
  colnames(df) <- switch(as.character(ncol(df)),
                         '23' = c('Time_UTC', 'CH4_ppm', 'CH4_ppm_sd', 'H2O_ppm', 
                                  'H2O_ppm_sd', 'CO2_ppm', 'CO2_ppm_sd', 'CH4d_ppm', 
                                  'CH4d_ppm_sd', 'CO2d_ppm', 'CO2d_ppm_sd', 'GasP_torr',
                                  'GasP_torr_sd', 'GasT_C', 'GasT_C_sd', 'AmbT_C', 
                                  'AmbT_C_sd', 'RD0_us', 'RD0_us_sd', 'RD1_us', 
                                  'RD1_us_sd', 'Fit_Flag', 'ID'),
                         '24' = c('Time_UTC', 'CH4_ppm', 'CH4_ppm_sd', 'H2O_ppm', 
                                  'H2O_ppm_sd', 'CO2_ppm', 'CO2_ppm_sd', 'CH4d_ppm', 
                                  'CH4d_ppm_sd', 'CO2d_ppm', 'CO2d_ppm_sd', 'GasP_torr',
                                  'GasP_torr_sd', 'GasT_C', 'GasT_C_sd', 'AmbT_C', 
                                  'AmbT_C_sd', 'RD0_us', 'RD0_us_sd', 'RD1_us', 
                                  'RD1_us_sd', 'Fit_Flag', 'MIU_v', 'ID'))
  dplyr::filter(df, !is.na(MIU))
}) %>% 
  bind_rows() %>%
  filter(!is.na(Time_UTC)) %>%
  arrange(Time_UTC)

# UTC Changeover --------------------------------------------------------------
# Remove data during 12-29-2015 to 12-30-2015 during which the sites were
# being changed from local time to UTC.
raw <- raw %>%
  filter(Time_UTC < as.POSIXct('2015-12-29', tz='UTC'),
         Time_UTC > as.POSIXct('2015-12-30', tz='UTC')) %>%
  mutate(pre_utc = Time_UTC > as.POSIXct('2015-12-30', tz='UTC'))

raw$Time_UTC(raw$pre_utc) <- as.POSIXct(format(raw$Time_UTC[raw$pre_utc], 
                                               tz='UTC'), tz='Denver') %>%
  select(-pre_utc) %>%
  filter(!duplicated(Time_UTC))

# Remove bad data -------------------------------------------------------------
# remove_bad() found in global.R
parsed <- remove_bad(raw, site) %>%
  mutate(ID = gsub('\\s+|V:{1}[0-9]', '', ID),
         tmp_split = stringr::str_split_fixed(ID, '~', 3)) %>%
  filter(nchar(ID) > 0,
         !is.na(ID),
         GasP_torr > 135,
         GasP_torr < 145)




# Remove trash strings, whitespace, extraneous characters, and valve indicators.
raw <- subset(raw, !grepl(paste(trash_strings, collapse='|'), MIU, fixed=TRUE))
raw <- subset(raw, !grepl(paste(trash_strings,collapse='|'), MIU))
raw$MIU <- gsub(paste(rem_strings,collapse='|'), '', raw$MIU, fixed=TRUE)
raw$MIU <- gsub(paste('\\s+|V:{1}[0-9]',paste(rem_strings,collapse='|'),sep='|'), '', raw$MIU)

# Remove any now empty MIU values.
raw <- subset(raw, nchar(MIU)>0 & !is.na(MIU))

# Split MIU into CO2 and CH4 columns.
MIU <- cbind('', raw$MIU, 'unknown')
twoGasMask <- grepl('~', raw$MIU, fixed=TRUE)
if (any(twoGasMask)){
  MIU[twoGasMask, ] <- matrix(data=unlist(strsplit(MIU[twoGasMask, 2], '~', fixed=TRUE)), ncol=3, byrow=TRUE)
}
MIU <- MIU[ ,2:3]

# Convert known standards to numeric values.
MIU[grepl('Atmosphere', raw$MIU, ignore.case=TRUE), ] <- -10
MIU[grepl('flush', raw$MIU, ignore.case=TRUE), ]      <- -99
MIU[MIU == 'unknown']                       <- -98
MIU <- matrix(data=as.numeric(MIU), ncol=2)

# Add adjusted MIU columns back to raw data
raw$MIU_co2 <- MIU[ , 1]
raw$MIU_ch4 <- MIU[ , 2]


# Define any MIU strings to trash data points (either literal or regular expression).
trash_strings <- c('Zero', '0.00', 'Disabled', 'V:2 Atmosphere',
                   'V:3 Atmosphere', 'V:4 Atmosphere', 'V:5 Atmosphere', 
                   'V:3 STD2 5469.15', 'meters', 'V:3 STD2 5469.15')
# Define any MIU strings that exist in addition to a numeric value (ie. tank ID).
rem_strings   <- c('_j11', '_21', '_47', 'STD[0-9]{1}')






uataq::archive(parsed, path=file.path('data', site, 'parsed/%Y_%m_parsed.dat'))

# Calibrations ----------------------------------------------------------------
if (cal_all) {
  files <- dir(file.path('data', site, 'parsed'), full.names=T)
} else files <- tail(dir(file.path('data', site, 'parsed'), full.names=T), 2)
parsed <- lapply(files, read_csv, locale=locale(tz='UTC')) %>% bind_rows()

cal <- with(parsed, 
            uataq::calibrate(Time_UTC, rawCO2, ID,
                             auto=T, er_tol=0.15, dt_tol=18000)) %>%
  rename(Time_UTC = time,
         CO2d_ppm_cal = cal)

uataq::archive(cal, path=file.path('data', site, 
                                   'calibrated/%Y_%m_calibrated.dat'))
