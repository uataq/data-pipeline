#' Calibrate trace gas data
#'
#' \code{calibrate_linear} applies a multi-point linear correction to
#' atmospheric trace gas data using reference tanks.
#'
#' @param time POSIXct timestamp, length n
#' @param meas numeric measured values, length n
#' @param known numeric gas concentration flag, length n. -10 for atmospheric
#'   observations, -99 for flush periods, or a positive value if sampling a known
#'   concentration
#' @param er_tol tolerated deviation from known value
#' @param drift_tol tolerated drift between subsequent calibrations
#' @param dt_tol maximum length of time to allow data outage and still calibrate data

calibrate_linear <- function(time, meas, known, er_tol = 100, drift_tol = 100, dt_tol = 18000) {
  
  require(dplyr)
  
  N <- length(time)
  qaqc <- rep.int(0, N)
  
  std_uniq <- unique(known[!is.na(known) & known >= 0])
  if (length(std_uniq) < 1) {
    out <- data.frame(time = time,
                      cal  = NA,
                      meas = meas,
                      m    = NA,
                      b    = NA,
                      n    = 0,
                      rsq = NA,
                      rmse = NA,
                      id = known,
                      qaqc = NA,
                      stringsAsFactors = F)
    return(out)
  }
  
  # Input coersion
  data <- data.frame(time = time, meas = as.numeric(meas), known = as.numeric(known))
  
  # Memory management
  rm('meas', 'known', 'time')
  invisible(gc())
  
  data <- data[order(data$time), ]
  data$dt <- with(data, c(NA, time[2:N] - time[1:(N-1)]))
  
  
  # Populate known and measured matrices -------------------------------------------------
  n_std <- length(std_uniq)
  n_obs <- nrow(data)
  
  stdk     <- matrix(std_uniq, nrow = n_obs, ncol = n_std, byrow = T)
  std_flag <- matrix(data$known, nrow = n_obs, ncol = n_std)
  std_flag[is.na(data$meas), ] <- NA
  
  # Mask for times when sampling any of the unique reference gases. Then, set atmospheric
  # sampling periods to NA. stdm then becomes a matrix with columns of known
  # concentrations, NA for atmosphere, and numeric values representing the measured
  # concentrations of the reference gas.
  stdm <- matrix(data$meas, nrow = n_obs, ncol = n_std)
  stdm[stdk != std_flag | is.na(std_flag)] <- NA
  
  # Determine elapsed time between reference sampling in same matrix format
  stdt <- matrix(data$time, nrow = n_obs, ncol = n_std)
  stdt[stdk != std_flag | is.na(std_flag)] <- NA
  
  # Memory management
  rm('std_flag')
  invisible(gc())
  
  # Calculate time elapsed between reference measurements
  stdtlast <- apply(stdt, 2, na_fill)
  stdtnext <- apply(stdt, 2, na_fill, backward = T)
  stdtelap <- apply(stdtnext - stdtlast, 2, zero_fill)
  
  # Memory management
  rm('stdt', 'stdtlast', 'stdtnext')
  invisible(gc())
  
  # Run length encoding ------------------------------------------------------------------
  # Apply run length encoding to slice data by each unique valve change and add an
  # identifier for each period. Reconstruct the original values with the additional index
  # column and perform averaging on each period (per_mean).
  run <- data$known %>%
    rle %>%
    unclass %>%
    as.data.frame(stringsAsFactors = F)
  
  data$idx <- run %>%
    mutate(values = 1:n()) %>%
    inverse.rle()
  
  data_grp <- data %>%
    group_by(idx)
  
  data$per_mean <- data_grp %>%
    summarize(values = mean(meas, na.rm = T)) %>%
    mutate(lengths = run$lengths) %>%
    inverse.rle()
  
  data$per_duration <- data_grp %>%
    summarize(values = as.numeric(max(time)) - as.numeric(min(time))) %>%
    mutate(lengths = run$lengths) %>%
    inverse.rle()
  
  stdm[!is.na(stdm)] <- rep.int(data$per_mean, n_std)[!is.na(stdm)]
  
  
  # Linear interpolation of measured reference -------------------------------------------
  # Remove any cases where a reference only appears for a single period. Calibration by
  # interpolating between measured values requires bracketing sampling periods with
  # reference values
  stdm[,apply(stdm, 2, function(x) length(which(!is.na(x)))) < 2] <- NA
  
  # Linearly interpolate each gas in stdm over atmospheric sampling periods when the
  # standard is not being measured.
  stdm <- apply(stdm, 2, uataq::na_interp, x = data$time)
  stdk[is.na(stdm)] <- NA
  stdm[is.na(stdk)] <- NA
  
  
  # QAQC ---------------------------------------------------------------------------------
  # Treat long-term standard as unknown prevent self-calibration
  sample_duration <- apply(stdtelap, 2, median, na.rm = T)
  lts_col <- sample_duration > dt_tol
  stdk[, lts_col] <- NA
  stdtelap[, lts_col] <- NA
  
  # Invalidate periods when difference between sequential reference gas measurements
  # exceeds drift_tol.
  delta <- rbind(rep.int(NA, ncol(stdm)),
                 abs(as.matrix(stdm[2:N, ] - stdm[1:(N-1), ])))
  mask <- delta > (drift_tol / stdtelap)
  stdk[mask] <- NA
  qaqc[rowSums(mask) > 0] <- -5
  
  # Invalidate periods with longer than dt_tol seconds between calibrations.
  mask <- stdtelap > dt_tol
  mask[is.na(mask)] <- F
  stdk[mask] <- NA
  qaqc[rowSums(mask) > 0] <- -6
  
  # Reference tank measurements out of range.
  # mask <- abs(stdm - stdk) > er_tol
  # mask[is.na(mask)] <- F
  # stdk[mask] <- NA
  # qaqc[rowSums(mask) > 0] <- -7
  
  # Invalidate stdm for cases above.
  stdm[is.na(stdk)] <- NA

  
  # Generate calibration coefficients ----------------------------------------------------
  # Identify the number of references used to calibrate each observation and perform
  # ordinary least squares regression to generate a linear representation of the
  # instrument drift. Then, apply the generated slope and intercept to the atmospheric
  # observations to correct.
  n_cal <- rowSums(!is.na(stdm))
  x     <- stdk
  y     <- stdm
  
  # Memory management
  rm('stdk', 'stdm')
  invisible(gc())
  
  xsum  <- rowSums(x,     na.rm = T)
  ysum  <- rowSums(y,     na.rm = T)
  xysum <- rowSums(x * y, na.rm = T)
  x2sum <- rowSums(x^2,   na.rm = T)
  y2sum <- rowSums(y^2,   na.rm = T)
  
  m <- (n_cal * xysum - xsum * ysum) / (n_cal * x2sum - xsum * xsum)
  b <- (x2sum * ysum - xsum * xysum) / (n_cal * x2sum - xsum * xsum)
  rsq <- (n_cal * xysum - xsum * ysum)^2 /
    ((n_cal * x2sum - xsum * xsum) * (n_cal * y2sum - ysum * ysum))
  fit_residuals <- (y - b) / m - x
  rmse <- sqrt(rowMeans(fit_residuals^2, na.rm = T))
  
  # Invalidate R-squared and RMSE without minimum 3 references
  invalid <- n_cal < 3
  rsq[invalid] <- NA
  rmse[invalid] <- NA
  
  # For periods with no calibration gases, set slope and intercept to NA
  n0 <- n_cal == 0
  m[n0] <- NA
  b[n0] <- NA
  
  # For periods with only a single calibration gas, assume that the instrument is
  # perfectly linear through zero and make only a slope correction
  n1 <- n_cal == 1
  if (ncol(x) < 2) {
    m[n1] <- y[n1,] / x[n1, ]
  } else {
    m[n1] <- rowSums(y[n1,], na.rm = T) / rowSums(x[n1, ], na.rm = T)
  }
  b[n1] <- 0
  
  return(data.frame(time = data$time,
                    cal  = (data$meas - b) / m,
                    meas = data$meas,
                    m    = m,
                    b    = b,
                    n    = n_cal,
                    rsq  = rsq,
                    rmse = rmse,
                    id   = data$known,
                    qaqc = qaqc,
                    stringsAsFactors = F))
}
