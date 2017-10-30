cr1000_tables <- function(ip) {
  uri <- paste0('https://air.utah.edu/api/cr1000_tables/?ip=', ip)
  response <- scan(uri, character(), sep = ',', quiet = T)
  return(response)
}