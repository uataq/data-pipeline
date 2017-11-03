calc_h2o_dilution <- function(tracer, H2O_ppm) {
  return(1e6 * (tracer/1e6 + tracer/1e6 * (1/(1-(H2O_ppm/1e6))) - tracer/1e6))
}
