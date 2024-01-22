rsync <- function(from, to, port = 22, quiet = F, stats = F, return.files = F) {
  cmd <- paste('/usr/bin/rsync -azut --exclude="archive/"',
               ifelse(stats, '--stats', ''),
               ifelse(return.files, '--out-format="%n"', ''),
               '-e "/usr/bin/ssh',
               '-i /uufs/chpc.utah.edu/common/home/u0791084/.ssh/id_rsa',
               '-o ConnectTimeout=5',
               '-p', port, '"', from, to,
               ifelse(quiet, '> /dev/null', ''))
  system(cmd, intern = return.files)
}
