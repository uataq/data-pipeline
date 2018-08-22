cr1000_is_online <- function(uri) {
  tryCatch(
    system(paste('curl -m 5', uri, '&> /dev/null')) == 0,
    error = function(e) F)
}