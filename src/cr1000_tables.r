cr1000_tables <- function(ip) {
  uri <- paste0('http://', ip, '/?command=browsesymbols&uri=dl:&format=json')
  response <- fromJSON(uri)$symbols$name
  return(response)
}