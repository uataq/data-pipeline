# James Mineau

gps_init <- function() {

  if (!site_config$reprocess) {
    # Rsync data from remote
    remote <- paste0('pi@', site_config$ip, ':/home/pi/data/', instrument, '/')
    local <- file.path('data', site, instrument, 'raw/')
    rsync(from = remote, to = local, port = site_config$port)

    n_files <- length(seq(last_time, as.POSIXct(Sys.Date()), by = 'day'))
  }

  read_nmea <- function(nmea) {

    if (!site_config$reprocess) {
      selector <- list.files(file.path('data', site, instrument, 'raw'),
                             pattern = nmea, full.names = T) %>%
        tail(n_files)
    } else {
      # TODO: at some point we need to process in batches to avoid memory issues
      selector <- file.path('data', site, instrument, 'raw',
                            paste0('*_', nmea, '.csv'))
    }

    lvl <- paste0('air_trend_', nmea)
    col_names <- data_config$gps[[lvl]]$col_names
    col_types <- data_config$gps[[lvl]]$col_types

    nd <- read_pattern(selector, colnums = seq(length(col_names)),
                       # match T in air-trend isoformat time col
                       pattern = 'T')

    if (is.null(nd) || nrow(nd) == 0) {
      return(NULL)
    }

    colnames(nd) <- col_names

    type_converter <- list(
      T = partial(fastPOSIXct, tz = 'UTC'),
      c = as.character,
      d = as.numeric
    )[unlist(strsplit(col_types, split=''))]
    names(type_converter) <- col_names

    nd <- nd %>%
      # Coerce column types
      mutate(across(all_of(col_names),
                    ~ type_converter[[cur_column()]](.))) %>%
      # Filter time
      rename(Time_UTC = time) %>%
      dplyr::filter(!is.na(Time_UTC)) %>%
      mutate(pi_date = as.Date(Time_UTC))

    return(nd)
  }

  gpgga <- read_nmea('gpgga')
  gprmc <- read_nmea('gprmc')

  # Merge GPGGA and GPRMC data
  nd <- full_join(gpgga, gprmc, by = c('pi_date', 'inst_time', 
                                       'latitude_dm', 'n_s',
                                       'longitude_dm', 'e_w'),
                  suffix = c("_gpgga", "_gprmc")) %>%
    mutate(
      inst_time = sprintf('%010.3f', as.numeric(inst_time)),
      latitude_deg = gps_dm2dd(latitude_dm),
      longitude_deg = -1 * gps_dm2dd(longitude_dm),
      speed_kmh = speed_kt * 1.852,
      inst_date = as.Date(sprintf('%06d', as.numeric(inst_date)),
                          format = '%d%m%y')
    )

  # There are potential issues with the timing of trx data. Without an active
  # network connection, the pi will not be able to sync its clock with the
  # network time. This can lead to the pi's clock being off. This can be
  # diagnosed using the gps time. However, for periods when only the gpgga
  # nmea strings were being recorded, we cannot guarantee the correct date.
  # This should only be issues near the start/end of each day and/or if the
  # pi was not connected to the network for a long period of time.
  # For now, we will accept the pi datetime from the gpgga data.
  # More work is needed to identify the exact dates that are incorrect.

  nd <- nd %>%
    rename(Time_UTC =  Time_UTC_gpgga) %>%
    select(Time_UTC, inst_date, inst_time, latitude_deg, longitude_deg,
           altitude_amsl, speed_kmh, true_course, n_sat,
           fix_quality, status)

  return(nd)
}