rsync <- function(from, to, port = 22) {
  cmd <- paste('/usr/bin/rsync -azqut --stats --exclude="archive/" -e',
               '"/usr/bin/ssh',
               '-i /uufs/chpc.utah.edu/common/home/u0791983/.ssh/id_rsa',
               '-o ConnectTimeout=5',
               '-p', port, '"', from, to, '> /dev/null')
  invisible(system(print(cmd, quote = F)))
}
