na_fill <- function (y, backward = F) {
  if (backward)
    y <- rev(y)
  nona <- which(!is.na(y))
  start <- head(nona, 1)
  end <- tail(nona, 1)
  if (length(end - start) < 1) 
    return(y)
  ysub <- y[start:end]
  idx <- which(is.na(ysub))
  ysub[idx] <- approx(1:length(ysub), ysub, xout = idx, method = 'constant')$y
  y[start:end] <- ysub
  
  if (backward)
    return(rev(y))
  return(y)
}