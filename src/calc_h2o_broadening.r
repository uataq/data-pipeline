#' Band broadening correction due to water vapor
#' @author Ben Fasoli
#'
#' Documentation for implementing band broadening corrections to the 4.26 um CO2
#' absorption band is provided by Licor at
#' \link{https://www.licor.com/documents/6yqgna9zt7y6avvg2azs} and
#' \link{https://www.licor.com/documents/042zyxu599e7sui3ev5q}. Variable conventions are
#' made to be consistent with Licor's documentation.
#' 
#' @param Cp measurement in which no band broadening correction was applied (umol mol-1)
#' @param w water vapor mole fraction (mol mol-1)
#' 
#' @return The corrected CO2 concentration (umol mol-1)
calc_h2o_broadening <- function(Cp, w) {
  Yc <- function(C) {
    a <- 6606.6
    b <- 1.4306
    c <- 2.2464 * 10^-4
    return((a + b*C^1.5) / (a + C^1.5) + c*C)
  }
  
  return((1 + 0.5*w) * Cp * (1 - 0.5*w*Yc(Cp)))
}
