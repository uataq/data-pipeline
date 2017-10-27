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



# Remote connection and data querying
query_cr1000 <- function(ip, table, t_start) {
  t_start <- format(t_start, tz = 'UTC', '%Y-%m-%dT%H:%M:%S')
  uri <- paste0('https://air.utah.edu/api/fetch_cr1000/?ip=', ip, '&table=', table,
                '&t_start=', t_start)
  message('Querying: ', uri)
  response <- scan(uri, character(), sep = '\n', quiet = T)
  data <- read.table(text = response, sep = ',', skip = 4, stringsAsFactors = F)
  colnames(data) <- scan(text = response[2], what = character(), sep = ',', quiet = T)
}
