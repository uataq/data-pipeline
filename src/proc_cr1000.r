proc_cr1000 <- function() {
  
  if (site_info[[site]]$reprocess) {
    # Read all historic raw data into memory as new data
    return(read_all(file.path('data', site, instrument, 'raw'),
                    col_names = data_info[[instrument]]$raw$col_names,
                    col_types = data_info[[instrument]]$raw$col_types))
  }
  
  # Query CR1000 for new records
  last_file <- get_last_file(file.path('data', site, instrument, 'raw'))
  last_time <- get_last_time(last_file)
  
  # TODO: temporary last time two days prior to now for testing
  last_time <- Sys.time() - 6*3600
  
  uri <- paste(site_info[[site]][[instrument]]$ip, 
               site_info[[site]][[instrument]]$port, sep = ':')
  table <- site_info[[site]][[instrument]]$cr1000_table
  nd <- cr1000_query(uri, table, last_time)
  nd$TIMESTAMP <- fastPOSIXct(nd$TIMESTAMP, tz = 'UTC')
  
  # Ensure columns conform to common specification
  nd <- nd[, data_info[[instrument]]$raw$col_names]
  
  if (ncol(nd) != length(data_info[[instrument]]$raw$col_names))
    stop('Invalid ', table, ' table returned by CR1000 query at: ', site)
  
  if (!all.equal(colnames(nd), data_info[[instrument]]$raw$col_names))
    stop('Invalid column structure returned by CR1000 query for: ', site, 
         '/', instrument)
  
  nd
}