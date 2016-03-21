# Ben Fasoli

# Reset flags -----------------------------------------------------------------
reset <- list(
  csp   = F,
  dbk   = F,
  fru   = F, 
  heb   = F,
  hpl   = F,
  lgn   = F,
  roo   = F,
  rpk   = F,
  sug   = F,
  sun   = F,
  trx01 = F,
  trx02 = F,
  wbb   = F
)

global_reset <- F


# Functions -------------------------------------------------------------------
remove_bad <- function(df, site) {
  bad <- readr::read_csv(paste0('lair-proc/bad/', site, '.txt'), 
                         locale=locale(tz='UTC'))
  for (i in 1:nrow(bad)) {
    if (grepl('all', bad$miu_old[i], ignore.case=T)) {
      mask <- df$Time_UTC >= bad$t_start[i] & 
        df$Time_UTC <= bad$t_end[i]
    } else {
      mask <- df$Time_UTC >= bad$t_start[i] & 
        df$Time_UTC <= bad$t_end[i] &
        grepl(bad$miu_old[i], df$ID)
    }
    df$ID[mask] <- bad$miu_new[i]
  }
  return(df)
}

# Lock file generation and management
lock_create <- function() {
  lockfile <- paste0('lair-proc/lock/', site, '.running')
  if (file.exists(lockfile)) stop(paste(site, 'processing already running.'))
  system(paste('touch', lockfile))
}

lock_remove <- function() {
  lockfile <- paste0('lair-proc/lock/', site, '.running')
  system(paste('rm', lockfile))
}