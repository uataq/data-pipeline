cr1000_query <- function(ip, table, t_start) {
  
  if (!cr1000_is_online(ip))
    stop('Unable to connect: ', site, ' at ', ip)
  
  if (!table %in% cr1000_tables(ip))
    stop(table, ' table not found at ', ip)
  
  t_start <- format(t_start, tz = 'UTC', '%Y-%m-%dT%H:%M:%S')
  
  uri <- paste0('http://', ip, '/?command=dataquery&uri=dl:', table, 
                '&format=TOA5&mode=since-time&p1=', t_start)
  
  if (interactive())
    message('Sending GET request to: ', uri)
  
  response <- scan(uri, character(), sep = '\n', quiet = T)
  header <- scan(text = response[2], what = character(), sep = ',', quiet = T)
  data <- read.table(text = response, sep = ',', skip = 4, stringsAsFactors = F)
  
  if (nrow(data) < 1)
    stop('No data returned by query at ', uri)
  
  setNames(data, header)
}