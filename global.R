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

global_reset <- T

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