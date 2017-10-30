ping <- function(site) {
  ip <- connect[[site]]$ip
  cmd <- paste('/usr/bin/ping -c 1 -W 5', ip)
  stdout <- suppressWarnings(system(cmd, intern = T, ignore.stderr = T))
  success <- nchar(stdout[2]) > 0
  return(success)
}