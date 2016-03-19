# Ben Fasoli

# Reset flags -----------------------------------------------------------------
reset <- list(
  csp = F,
  dbk = F,
  fru = F, 
  heb = F,
  hpl = F,
  lgn = F,
  roo = F,
  rpk = F,
  sug = F,
  sun = F,
  trx01 = F,
  trx02 = F,
  wbb = F
)

global_reset <- T

# Functions -------------------------------------------------------------------
remove_bad <- function(df, site) {
  bad <- readr::read_csv(paste0('uataq-proc/bad/', site, '.txt'), 
                         locale=locale(tz='UTC'))
  with(bad, {
    for (i in 1:length(miu_old)) {
      if (grepl('all', miu_old[i], ignore.case=T)) {
        mask <- df$Time_UTC >= t_start[i] & 
          df$Time_UTC <= t_end[i]
        df   <- subset(df, !mask)
      } else {
        mask <- df$Time_UTC >= t_start[i] & 
          df$Time_UTC <= t_end[i] &
          grepl(miu_old[i], df$ID)
        df$ID[mask] <- miu_new[i]
      }
    }
  })
  return(df)
}