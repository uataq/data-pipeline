#' Dilution correction due to water vapor
#' @author Ben Fasoli
#'
#' Correction for the dilution effect of water vapor on measured CO2 concentration using
#' law of partial pressures. Results have been validated and are consistent with methods
#' described previously by
#' 
#' Andrews, A. E., and Coauthors, 2014: CO2, CO, and CH4 measurements from tall towers in
#' the NOAA earth system research laboratory’s global greenhouse gas reference network: 
#' Instrumentation, uncertainty analysis, and recommendations for future high-accuracy 
#' greenhouse gas monitoring efforts. Atmos. Meas. Tech., 7, 647–687, 
#' doi:10.5194/amt-7-647-2014.
#' 
#' @param tracer measurement in which dilution correction was applied (umol mol-1)
#' @param H2O_ppm water vapor mole fraction (mmol mol-1)
#' 
#' @return The corrected tracer concentration (umol mol-1)
calc_h2o_dilution <- function(tracer, H2O_ppm) {
  return(1e6 * (tracer/1e6 * (1/(1-(H2O_ppm/1e6)))))
}
