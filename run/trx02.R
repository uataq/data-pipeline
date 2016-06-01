# Ben Fasoli

# Parameters ------------------------------------------------------------------
site   <- 'trx02'
ip     <- 'uuhorel-01.eairlink.com'
port   <- 8022
inst <- c('gps', 'met', 'metone', '2bo3')

# Processing ------------------------------------------------------------------
source('/uufs/chpc.utah.edu/common/home/lin-group2/measurements/lair-proc/fun/trx.R')

q('no')