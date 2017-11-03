calc_h2o <- function(RH_pct, P_Pa, T_C) {
  
  T_K <- T_C + 273.15

  # Hyland and Wexler saturation vapor pressure formulation
  es_Pa <- exp(-0.29912729e4    * T_K^(-2)  +
                 -0.60170128e4  * T_K^(-1)  +
                 0.1887643854e2 * T_K^(0)  + 
                 -0.28354721e-1 * T_K^(1)  +
                 0.17838301e-4  * T_K^(2)  +
                 -0.84150417e-9 * T_K^(3)  +
                 0.44412543e-12 * T_K^(4)  +
                 0.2858487e1    * log(T_K))
  
  # Augustus Roche Magnus approximation of Clausius Clapeyron
  # es_Pa <- 610.94 * exp((17.623*T_C) / (T_C+243.04))
  
  e_Pa <- (RH_pct/100) * es_Pa
  H2O_ppm <- (e_Pa/P_Pa) * 1e6
  return(H2O_ppm)
}
