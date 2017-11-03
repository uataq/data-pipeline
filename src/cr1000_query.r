cr1000_query <- function(ip, table, t_start) {
  
  # if (!ping(ip))
    # stop('No ping returned from ', ip)
  
  if (!table %in% cr1000_tables(ip))
    stop(table, ' table not found at ', ip)
  
  t_start <- format(t_start, tz = 'UTC', '%Y-%m-%dT%H:%M:%S')
  
  uri <- paste0('https://air.utah.edu/api/cr1000_query/?ip=', ip, '&table=', table,
                '&t_start=', t_start)
  
  print(uri)
  
  response <- scan(uri, character(), sep = '\n', quiet = T)
  data <- read.table(text = response, sep = ',', skip = 4, stringsAsFactors = F)
  
  if (nrow(data) < 1)
    stop('No data returned by query at ', uri)
  
  colnames(data) <- scan(text = response[2], what = character(), sep = ',', quiet = T)
  return(data)
}