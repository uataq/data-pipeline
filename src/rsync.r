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
                                # Legacy SHA-1 algorithms for old LGR onboard computers,
                                # disabled system-wide by CHPC's NOSHA1-SSH crypto policy
                                # (2026-08-28)
                                '-o HostKeyAlgorithms=+ssh-rsa',
                                '-o PubkeyAcceptedKeyTypes=+ssh-rsa',
                                '-o KexAlgorithms=+diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1',
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
