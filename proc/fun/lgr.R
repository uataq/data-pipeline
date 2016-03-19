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

if (reset[[site]] | globalReset) {
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

# Read files ------------------------------------------------------------------
raw <- lapply(tfs, function(tf) {
  tryCatch(readr::read_csv(tf, col_names=F, skip=2, na=c('TO', '', 'NA'),
                           locale=locale(tz='UTC')), error=function(e){NULL})
}) %>% bind_rows()





