# Ben Fasoli

# Run flags -------------------------------------------------------------------
run <- list(
  csp   = F,
  dbk   = T,
  fru   = T,
  hdp   = T,
  heb   = T,
  hpl   = T,
  imc   = T,
  lgn   = T,
  roo   = T,
  rpk   = T,
  sug   = T,
  sun   = T,
  trx01 = T,
  trx02 = T,
  wbb   = T
)


# Reset flags -----------------------------------------------------------------
reset <- list(
  csp   = F,
  dbk   = F,
  fru   = F,
  hdp   = F,
  heb   = F,
  hpl   = F,
  imc   = F,
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
                         locale=locale(tz='UTC'), col_types = 'TTcc_')
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

# Bad data reset
check_bad <- function() {
  badf <- dir('lair-proc/bad', pattern=site, full.names=T)
  mt <- badf %>%
    file.info %>%
    .$mtime

  mt_df <- readRDS('lair-proc/bad/_log.rds')
  if (trunc(mt) != trunc(mt_df[site, 'mtime'])) {
    mt_df[site, 'mtime'] <- mt
    saveRDS(mt_df, 'lair-proc/bad/_log.rds')
    reset[[site]] <<- T

    # Generate initial:
    #     badf <- dir('bad', pattern='txt', full.names=T)
    #     mt <- badf %>%
    #       file.info %>%
    #       .$mtime
    #     df <- data.frame(stringsAsFactors=F, mtime = mt)
    #     rownames(df) <- basename(tools::file_path_sans_ext(badf))
    #     df$site <- NULL
    #     saveRDS(df, 'lair-proc/bad/_log.rds')
  }
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
