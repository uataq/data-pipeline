cr1000_init <- function() {

  if (site_config$reprocess) {
    # Read all historic raw data into memory as new data
    files <- dir(file.path('data', site, instrument, 'raw'), full.names = T)
    if (length(files) == 0)
      stop('No prior data found: ', file.path('data', site, instrument, 'raw'))
    return(read_files(files))
  }

  # Query CR1000 for new records
  last_file <- tail(dir(file.path('data', site, instrument, 'raw'),
                    pattern = '.*\\.{1}dat', full.names = T), 1)
  if (length(last_file) == 0)
    stop('No prior data found: ', file.path('data', site, instrument, 'raw'))
  last_time <- get_last_time(last_file)

  uri <- paste(site_config$ip, site_config$port, sep = ':')
  table <- switch(instrument,
                  'licor_6262' = 'Dat',
                  'metone_es642' = 'PM')
  nd <- cr1000_query(uri, table, last_time + 5)
  nd$TIMESTAMP <- fastPOSIXct(nd$TIMESTAMP, tz = 'UTC')

  # Ensure columns conform to common specification
  nd <- nd[, data_config[[instrument]]$raw$col_names]

  if (ncol(nd) != length(data_config[[instrument]]$raw$col_names))
    stop('Invalid ', table, ' table returned by CR1000 query at: ', site)

  if (!all.equal(colnames(nd), data_config[[instrument]]$raw$col_names))
    stop('Invalid column structure returned by CR1000 query for: ', site,
         '/', instrument)
  
  message('New data:')
  str(nd)

  nd
}
