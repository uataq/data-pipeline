# James Mineau

air_trend_init <- function(hostname = site_config$ip, port = site_config$port, name = NULL) {

  wd <- file.path('data', site, instrument, 'raw')

  files <- list.files(wd, pattern = '\\.csv', full.names = T)

  # air-trend name
  # ex: trx01 has instrument == lgr_ugga_manual_cal,
  #     but air-trend name is lgr_ugga
  if (is.null(name)) name <- instrument

  # Get column names and types from data_config
  col_names <- data_config[[name]][['air_trend']]$col_names
  col_types <- data_config[[name]][['air_trend']]$col_types

  if (!should_reprocess()) {

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
    remote <- paste0('pi@', hostname, ':/home/pi/data/', name, '/')
    local <- file.path(wd, '')
    rsync(from = remote, to = local, port = port)

    # Process daily files as one batch
    batches <- list(seq(as.Date(last_time), Sys.Date(), by = 'day'))

  } else {
    # Reprocess raw data in yearly batches
    batches <- unique(substr(basename(files), 1, 4))
  }

  nd <- lapply(batches, function(batch) {
    # Read in data
    selector <- file.path(wd, paste0(batch, '*.csv'))
    nd <- read_pattern(selector, colnums = seq_along(col_names),
                       pattern = 'T')  # match T in air-trend isoformat time col

    if (is.null(nd) || nrow(nd) == 0) return(NULL)

    colnames(nd) <- col_names

    nd <- nd %>%
      # Coerce column types
      mutate(time = fastPOSIXct(time, tz = 'UTC')) %>%
      mutate(across(which(unlist(strsplit(col_types, '')) == 'd'),
                    as.numeric)) %>% suppressWarnings() %>%
      # Filter and sort by time
      rename(Time_UTC = time) %>%
      dplyr::filter(!is.na(Time_UTC))

    return(nd)
  }) %>%
    bind_rows()

  print_nd()
  return(nd)
}