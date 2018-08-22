zero_fill <- function (y, backward = F) {
  if (backward)
    y <- rev(y)
  nozero <- which(y != 0)
  start <- head(nozero, 1)
  end <- length(y)
  if (length(end - start) < 1) 
    return(y)
  ysub <- y[start:end]
  ysub[ysub == 0] <- NA
  ysub <- c(ysub, -1)
  xout <- seq_along(ysub)
  y[start:end] <- approx(ysub, xout = xout, method = 'constant')$y[-length(xout)]
  
  if (backward)
    return(rev(y))
  return(y)
}