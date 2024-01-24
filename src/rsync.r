rsync <- function(from, to, port = 22, stats = F, return.files = F, quiet = F) {
  message('rsyncing from ', from)

  cmd <- '/usr/bin/rsync'
  args <- c('-azut',
            '--exclude="archive/"',
            ifelse(stats, '--stats', ''),
            ifelse(return.files, '--out-format="%n"', ''),
            '-e', shQuote(paste('/usr/bin/ssh',
                                '-i /uufs/chpc.utah.edu/common/home/u0791084/.ssh/id_rsa',
                                '-o ConnectTimeout=5',
                                '-p', port)),
            from, to,
            ifelse(quiet, '> /dev/null', ''))
  result <- suppressWarnings(system2(cmd, args, stdout = T, stderr = T))

  # Check status
  status <- attr(result, 'status')
  if (!is.null(status)) {
    switch(as.character(status),
      '0' = NULL,
      '255' = stop('unable to connect.', call. = F),
      stop('rsync failed with status ', status, call. = F)
    )
  }

  return(result)
}
