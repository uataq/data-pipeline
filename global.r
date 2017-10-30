# Ben Fasoli

# Connection info ------------------------------------------------------------------------
connect <- list(
  csp = list(ip = '69.55.97.78', port = 22),
  dbk = list(ip = '166.130.22.212', port = 3001),
  fru = list(ip = '166.130.125.75', port = 22),
  hdp = list(ip = '50.224.25.93', port = 22),
  heb = list(ip = '166.130.69.244', port = 3001),
  hpl = list(ip = '166.130.104.236', port = 22),
  imc = list(ip = '67.128.146.28', port = 6785),
  lgn = list(ip = '129.123.46.97', port = 6785),
  roo = list(ip = '166.130.125.77', port = 22),
  rpk = list(ip = '205.127.188.48', port = 6785),
  sug = list(ip = '166.130.89.167', port = 3001),
  sun = list(ip = '107.1.14.185', port = 6785),
  trx01 = list(ip = '', port = 22),
  trx02 = list(ip = '', port = 22),
  wbb = list(ip = 'GGA-13-0221.chpc.utah.edu', port = 22)
)

# Active flags ---------------------------------------------------------------------------
active <- list(
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

# Reset flags ----------------------------------------------------------------------------
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
