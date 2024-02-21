# James Mineau

air_trend_init <- function(hostname = site_config$ip, name = NULL) {

  wd <- file.path('data', site, instrument, 'raw')

  # air-trend name
  # ex: trx01 has instrument == lgr_ugga_manual_cal,
  #     but air-trend name is lgr_ugga
  if (is.null(name)) name <- instrument

  if (!site_config$reprocess) {

    # Get last time of data in site/instrument/raw directory
    files <- list.files(wd, pattern = '\\.csv', full.names = T)
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
    rsync(from = remote, to = local, port = site_config$port)

    batches <- seq(as.Date(last_time), Sys.Date(), by = 'day')
    selector <- file.path(wd, paste0(batches, '.csv'))

  } else {
    # TODO: at some point we need to process in batches to avoid memory issues
    selector <- file.path(wd, '*')
  }

  # Get column names and types from data_config
  col_names <- data_config[[name]][['air_trend']]$col_names
  col_types <- data_config[[name]][['air_trend']]$col_types

  # Read in data
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
    dplyr::filter(!is.na(Time_UTC)) %>%
    arrange(Time_UTC)

  print_nd()
  return(nd)
}