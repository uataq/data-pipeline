# James Mineau

proc_gps <- function() {

  library(dtplyr)
  library(parallel)

  # Date when the rmc data started being collected permanently
  # - we want to drop rows with only gga data after this date
  rmc_start_date <- list('trx01' = '2018-01-19',
                         'trx02' = '2023-10-04')

  # Storage location of vehicles
  # - Jordan River Rail Service Center
  JRRSC <- list(xmin = -111.9221, ymin = 40.7210,
                xmax = -111.9177, ymax = 40.7234)

  storage <- switch(site,
                    'trx01' = JRRSC,
                    'trx02' = JRRSC,
                    NULL)

  wd <- file.path('data', site, instrument, 'raw')

  files <- list.files(wd, pattern = '\\.csv', full.names = T)


  proc_batch <- function(batch) {
    read_nmea_batch <- function(nmea) {

      selector <- file.path(wd, paste0(batch, '*_', nmea, '.csv'))

      lvl <- paste0('air_trend_', nmea)
      col_names <- data_config$gps[[lvl]]$col_names
      col_types <- data_config$gps[[lvl]]$col_types

      time_regex <- '^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?$'

      df <- read_pattern(selector, colnums = seq_along(col_names),
                         # match T in air-trend isoformat time col
                         pattern = 'T')

      if (is.null(df) || nrow(df) == 0) return(NULL)

      colnames(df) <- col_names

      df <- df %>%
        lazy_dt() %>%  # data.table speed with dplyr syntax

        # Drop rows with invalid directions (bad parsing)
        dplyr::filter(n_s %in% c('N', 'S') & e_w %in% c('E', 'W')) %>%

        # Remove duplicates
        distinct() %>%

        # Drop rows where time does not match the format %Y-%m-%dT%H:%M:%OS
        dplyr::filter(grepl(time_regex, time)) %>%

        # Coerce column types
        mutate(time = fastPOSIXct(time, tz = 'UTC')) %>%
        mutate(across(which(unlist(strsplit(!!col_types, '')) == 'd'),
                      as.numeric)) %>% suppressWarnings() %>%
        mutate(inst_time = as.numeric(inst_time)) %>%

        # Drop rows where time, latitude, or longitude is NA
        dplyr::filter(!is.na(time) & !is.na(inst_time) &
                      !is.na(latitude_dm) & !is.na(longitude_dm)) %>%

        mutate(
          # Convert inst_time back to string with leading 0's
          inst_time = sprintf('%010.3f', inst_time),

          # Extract the date from the pi's time to use for merging
          pi_date = as.Date(time),

          # Calculate the number of seconds since midnight
          pi_seconds = hour(time) * 3600 + minute(time) * 60 + second(time),
          gps_seconds = (as.numeric(substr(inst_time, 1, 2)) * 3600 +
                         as.numeric(substr(inst_time, 3, 4)) * 60 +
                         as.numeric(substr(inst_time, 5, nchar(inst_time)))),

          # Calculate the difference in seconds between the pi and gps time
          abs_diff = abs(gps_seconds - pi_seconds)) %>%

        # Handle duplicate inst_time's for the same pi_date

        # Sort by pi_date, inst_time, and time for efficient grouping
        # - script doesn't care about the order of the rows
        # - reverse the sort order to keep the last row in the group
        arrange(pi_date, inst_time, -time) %>%

        # Drop duplicate rows where the pi's time is within 60s of the prev row
        # - keep the last row in the group (more likely to be post sync)
        # - duplicate rows within 10s are likely due to gps syncing with sats
        # - duplicate rows > 60s are likely due to an incorrect pi time
        group_by(pi_date, inst_time) %>%
        filter((abs(difftime(time, lag(time), units = "secs")) > 60)
               | n() == 1) %>%
        ungroup()

      return(as.data.frame(df))
    }

    message(paste('Processing batch:', batch))

    raw_data <- mclapply(c('gpgga', 'gprmc'), read_nmea_batch, mc.cores = 2)
    gga <- raw_data[[1]]
    rmc <- raw_data[[2]]

    if (is.null(gga) || nrow(gga) == 0) return(NULL)

    # Merge with rmc time if available
    if (!is.null(rmc) && nrow(rmc) > 0) {

      # Set rmc time as Time_UTC
      rmc <- rmc %>%
        mutate(inst_date = suppressWarnings(as.integer(inst_date))) %>%
        drop_na(inst_date) %>%
        mutate(inst_date = sprintf('%06d', inst_date),
               Time_UTC = as.POSIXct(paste(inst_date, inst_time),
                                     format = '%d%m%y %H%M%OS', tz = 'UTC'),
               Speed_m_s = speed_kt * 0.514444) %>%
        select(-inst_date, -speed_kt)

      # Merge the two dataframes
      # Merging on 'pi_date' and 'inst_time' is the preferred approach.
      # Although there can be many-to-many matches between these fields
      #  due to potential discrepancies near the start/end of the day
      #  and between NMEA messages, this method ensures consistent locations
      #  for the same time.
      # Using the pi's 'time' for merging is not recommended as it can vary for
      #  the same NMEA time-location pair and is not consistently shared between
      #  messages in the modern air-trend program likely due to its queue system
      nd <- left_join(gga, rmc, suffix = c('', '_rmc'),
                      by = c('pi_date', 'inst_time',
                             'latitude_dm', 'longitude_dm',
                             'n_s', 'e_w'),
                      relationship = 'many-to-many') %>%

        # Drop rows that have the same gga & rmc time
        #  if both times are the same, the entire row is likely a duplicate
        # distinct(time, time_rmc, .keep_all = TRUE) %>%
        unique(by = c('time', 'time_rmc')) %>%

        # If difference in the pi's time between the two messages is too large,
        #  then it is probably a bad merge - drop it, not worth trying to fix
        #   if it is negative, the pi probably synced with an ntp server
        #    in the middle of recording the gga and rmc messages
        #  or it could be an rmc message was skipped (but beyond 5s is a lot)
        dplyr::filter((abs(difftime(time, time_rmc, units = 'secs')) < 5)
                      | is.na(time_rmc)) %>%

        # Drop gga only rows after the collection of rmc data started
        #  - essentially performs an inner join after the rmc data starts
        # (this is a little hacky, but prevents techs
        #  from needing to continue qaqcing time data)
        dplyr::filter(time < as.POSIXct(rmc_start_date[[site]],
                                        format = '%Y-%m-%d', tz = 'UTC')
                      | !is.na(time_rmc))
    } else {
      # Add rmc columns to gga data
      nd <- gga %>%
        mutate(Time_UTC = as.POSIXct(NA),
               Speed_m_s = NA, true_course = NA, status = NA)
    }

    # Memory management
    rm(raw_data, gga, rmc)
    invisible(gc())

    nd <- nd %>%
      # Convert latitude and longitude to decimal degrees
      mutate(Latitude_deg = (ifelse(n_s == 'N', 1, -1)
                             * gps_dm2dd(latitude_dm)),
             Longitude_deg = (ifelse(e_w == 'E', 1, -1)
                              * gps_dm2dd(longitude_dm)))  %>%
      select(-latitude_dm, -longitude_dm, -n_s, -e_w) %>%

      # Rename columns
      rename(Altitude_msl = altitude_amsl,
             Course_deg = true_course,
             Fix_Quality = fix_quality,
             N_Sat = n_sat,
             Status = status)

    # Initialize QAQC_Flag
    nd$QAQC_Flag <- 0

    # Apply manual qaqc definitions in bad/site/instrument.csv
    nd <- nd %>%
      # bad_data_fix operates on Time_UTC, but we don't always have it from gps
      # - Need to reference pi's time in bad gps files
      # - Temporarily rename time columns
      rename(Time_UTC = time,
             time_gps = Time_UTC) %>%
      # Initialize 'ok' ID column to specify ahead/behind/drop
      mutate(ID = 'ok') %>%
      bad_data_fix() %>%
      rename(Pi_Time = Time_UTC,
             Time_UTC = time_gps)

    # Drop specified rows due to bad characters, duplicates, etc.
    nd <- nd[nd$ID != 'drop', ]

    # Set QAQC Flags
    # https://github.com/uataq/data-pipeline#qaqc-flagging-conventions
    is_manual_pass <- nd$QAQC_Flag == 1
    is_manual_removal <- nd$QAQC_Flag == -1

    if (!is.null(storage)) {
      nd$QAQC_Flag[with(nd, Latitude_deg > storage$ymin &
                          Latitude_deg < storage$ymax &
                          Longitude_deg > storage$xmin &
                          Longitude_deg < storage$xmax)] <- 20
    }

    nd$QAQC_Flag[with(nd, !(Fix_Quality %in% c(1, 2)))] <- -21
    nd$QAQC_Flag[with(nd, N_Sat < 4)] <- -22
    nd$QAQC_Flag[with(nd, !is.na(Time_UTC) & Status != 'A')] <- -23
    # nd$QAQC_Flag[filter_warmup(nd, cooldown = '5M', warmup = '1M')] <- -24  # takes a really long time - not worth it

    nd$QAQC_Flag[is_manual_pass] <- 1
    nd$QAQC_Flag[is_manual_removal] <- -1

    # Apply time adjustments
    ahead <- nd$ID == 'ahead'
    behind <- nd$ID == 'behind'
    above <- nd$pi_seconds < nd$gps_seconds
    below <- nd$pi_seconds > nd$gps_seconds
    outlier <- nd$abs_diff > 5

    day_ahead <- ahead & above & outlier
    nd$pi_date[day_ahead] <- nd$pi_date[day_ahead] - 1

    day_behind <- behind & below & outlier
    nd$pi_date[day_behind] <- nd$pi_date[day_behind] + 1

    mask <- is.na(nd$Time_UTC)
    nd$Time_UTC[mask] <- as.POSIXct(paste0(nd$pi_date[mask],
                                           nd$inst_time[mask]),
                                    format = '%Y-%m-%d%H%M%OS', tz = 'UTC')

    # Format Pi Time
    nd <- nd %>%
      mutate(Pi_Time = format(Pi_Time, tz = 'UTC',
                              format = '%Y-%m-%d %H:%M:%OS2'))

    # Reduce to QAQC columns
    qaqc_cols <- data_config[['gps']]$qaqc$col_names
    nd <- nd[, qaqc_cols]

    return(nd)
  }


  if (!site_config$reprocess) {

    # Get last time of data in site/instrument/raw directory
    last_file <- tail(files, 1)
    if (length(last_file) == 0) {
      warning('No prior data found: ', wd)
      last_time <- as.POSIXct('1970-01-01', tz = 'UTC')
    } else {
      last_time <- get_last_time(last_file, format = '%Y-%m-%dT%H:%M:%S')
      if (is.null(last_time)) {
        # If last_time is NULL, read in last two days of data
        last_time <- Sys.Date() - 1
      }
    }

    # Rsync data from remote
    remote <- paste0('pi@', site_config$ip, ':/home/pi/data/', instrument, '/')
    local <- file.path(wd, '')
    rsync(from = remote, to = local, port = site_config$port)

    # Process daily files as one batch
    batch <- seq(as.Date(last_time), Sys.Date(), by = 'day')
    nd <- proc_batch(batch)
    print_nd()

  } else {
    # Reprocess raw data in yearly batches
    batches <- unique(substr(basename(files), 1, 4))
    nd <- mclapply(batches, proc_batch, mc.cores = 10) %>%
      bind_rows()
  }

  # Sort by Time_UTC
  nd <- nd[order(nd[['Time_UTC']]), ]

  return(nd)
}