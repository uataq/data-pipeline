# Ben Fasoli

# Parameters -------------------------------------------------------------------
site   <- 'wbb'
ip     <- 'GGA-13-0221.chpc.utah.edu'

# Processing -------------------------------------------------------------------
source('/uufs/chpc.utah.edu/common/home/lin-group2/measurements/lair-proc/fun/lgr-ugga.r')

# UATAQ Brain ------------------------------------------------------------------
brain_instruments <- c('teledyne-t400', 'teom-1400ab')
for (inst in brain_instruments) {
  cmd <- paste0('/usr/bin/rsync -avz -e ',
                '"/usr/bin/ssh -i /uufs/chpc.utah.edu/common/home/u0791983/.ssh/id_rsa" ',
                'uataq@uataq-brain.atmos.utah.edu:/home/uataq/air-trend/log/data/', inst, '/* ',
                '/uufs/chpc.utah.edu/common/home/lin-group2/measurements/data/wbb/', inst, '/raw/')
  system(print(cmd, quote=F))
}


q('no')