#!/uufs/chpc.utah.edu/sys/installdir/R/3.4.2i/bin/Rscript
# Ben Fasoli
setwd('~/links/lin-group2/measurements-beta/')

library(tidyverse)

path <- list(
  v3 = '~/links/lin-group2/measurements-beta/data/',   # uucon beta
  v2 = '~/links/lin-group2/measurements/data/',        # uucon active
  v1 = '~/links/lin-group6/lem/measurements/data/'     # lem slcco2
)

# Ensure v2 is at latest git commit
system(paste('/uufs/chpc.utah.edu/sys/installdir/git/2.10.0-c7/bin/git -C',
             '~/links/lin-group2/measurements/lair-proc pull'))

# Wipe v3 lock files
system('rm proc/.lock/*')

# Merge data sources -----------------------------------------------------------
# Reinitialize beta data directory
message('Reinitializing data paths')
cmd <- paste('rm -r', path$v3, '; mkdir -p', path$v3)
system(cmd)

# Sync v2 raw datase
message('Syncing UUCON data archive')
cmd <- paste('rsync -av',
             '--exclude="calibrated"',
             '--exclude="parsed"',
             '--exclude="geoloc"', 
             # '--exclude="trx01"',  #temporary to reduce transfer time
             # '--exclude="trx02"',  #temporary to reduce transfer time
             #'--dry-run',
             path$v2, 'data/')
system(cmd)

# Sync v1 raw data
message('Syncing SLCCO2 data archive')
cmd <- paste('rsync -av --exclude="calibrated" --exclude="parsed"', 
             '--exclude="desktop.ini"',
             # '--dry-run',
             path$v1, 'data/')
system(cmd)


# Migrate formatting conventions -----------------------------------------------
# Replace dashes with underscores in naming conventions for programatic use
sites <- dir('data')
for (site in sites) {
  instruments <- dir(file.path('data', site))
  for (instrument in instruments) {
    instrument_new <- gsub('-', '_', instrument, fixed = T)
    if (instrument_new != instrument) {
      cmd <- paste('mv', 
                   file.path('data', site, instrument), 
                   file.path('data', site, instrument_new))
      message('Renaming: ', site, '/', instrument)
      system(cmd)
    }
  }
}

# Move trax formatting from raw/inst to inst/raw
base_path <- 'data/trx01/raw'
insts <- dir(base_path, full.names = T)
for (i in insts) {
  system(paste('mv', i, 'data/trx01/'))
}
system('rmdir data/trx01/raw')
system('mv data/trx01/lgr data/trx01/lgr_ugga')
system('mkdir data/trx01/lgr_ugga/raw')
system('mv data/trx01/lgr_ugga/*.dat data/trx01/lgr_ugga/raw/')

# Add column headers to raw files
source('proc/_global.r')
# Removing since this adds a layer of extra data processing necessary with 
# rsync'ed raw data
# files <- dir('data', pattern = 'raw.dat', recursive = T)
# files_split <- strsplit(files, '/')
# 
# site <- sapply(files_split, function(x) x[1])
# instrument <- sapply(files_split, function(x) x[2])
# 
# files <- file.path('data', files)
# for (i in 1:length(files)) {
#   hdr_std <- paste(data_info[[instrument[i]]]$raw$col_names, collapse = ',')
#   if (nchar(hdr_std) == 0) next
#   
#   hdr_is <- readLines(files[i], 1)
#   
#   if (hdr_is != hdr_std) {
#     message('Adding header to: ', files[i])
#     cmd <- paste0('echo "', hdr_std, '" | cat - ', files[i], 
#                   ' > tmp && mv tmp ', files[i])
#     system(cmd)
#   }
# }


# Migrate bad data definitions -------------------------------------------------
# Reinitialize new bad data archive
message('Migrating bad data definitions')
cmd <- 'rm -r proc/bad; mkdir proc/bad'
system(cmd)


# Sync most recent bad data definitions into new format
files <- dir('~/links/lin-group2/measurements/lair-proc/bad', pattern = 'txt', 
             full.names = T)
for (file in files) {
  site <- basename(tools::file_path_sans_ext(file))
  instruments <- dir(file.path('data', site))
  instrument <- intersect(instruments, c('licor_6262', 'lgr_ugga'))
  if (length(instrument) != 1) stop('Bad instrument definition')
  print(file)
  df <- read_csv(file, col_types = 'TTccc', locale = locale(tz = 'UTC'))
  
  # Retain comment
  comment <- df$comment
  df$comment <- NULL
  
  # Split comment fields
  split <- stringr::str_split_fixed(comment, ':', 2)
  
  # Create new fields
  df$t_added <- Sys.time()
  attributes(df$t_added)$tzone <- 'UTC'
  df$name <- split[, 1]
  df$comment <- gsub('^ ', '', split[, 2])
  
  # Output file in new directory structure
  new_file <- file.path('proc', 'bad', site, paste0(instrument, '.csv'))
  new_dir <- dirname(new_file)
  cmd <- paste('mkdir -p', new_dir)
  system(cmd)
  write_csv(df, new_file)
}



