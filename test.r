# Ben Fasoli

setwd('~/../lin-group2/measurements-beta/lair-proc/')
invisible(lapply(dir('src', full.names = T), source))
source('global.r')

# Function testing
site   <- 'dbk'
ip     <- connect[[site]]$ip

can_ping <- ping(ip)
tables <- cr1000_tables(ip)
dat <- cr1000_query(ip, 'Dat', Sys.time() - 60 * 5)
pm <- cr1000_query(ip, 'PM', Sys.time() - 60 * 5)

