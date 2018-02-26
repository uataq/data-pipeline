rsync <- function(from, to, port = 22) {
  cmd <- paste('/usr/bin/rsync -azq --stats --exclude="archive/" -e',
               '"usr/bin/ssh',
               '-i /uufs/chpc.utah.edu/common/home/u0791983/.ssh/id_rsa',
               '-p', port, '"',
               from, to)
  system(print(cmd, quote = F))
}