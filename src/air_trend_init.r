# James Mineau

air_trend_init <- function(hostname = site_config$ip, name = NULL) {

  if (!site_config$reprocess) {
    # Rsync data from remote
    remote <- paste0('pi@', hostname, ':/home/pi/data/', instrument, '/')
    local <- file.path('data', site, instrument, 'raw/')
    rsync(from = remote, to = local, port = site_config$port)

    n_files <- length(seq(last_time, as.POSIXct(Sys.Date()), by = 'day'))
    selector <- list.files(file.path('data', site, instrument, 'raw'),
                           full.names = T, pattern = '.csv') %>%
      tail(n_files)

  } else {
    # TODO: at some point we need to process in batches to avoid memory issues
    # n_files <- Inf
    selector <- file.path('data', site, instrument, 'raw/*')
  }


  # Get column names and types from data_config
  if (is.null(name)) name <- instrument
  col_names <- data_config[[name]][['air_trend']]$col_names
  col_types <- data_config[[name]][['air_trend']]$col_types

  # Read in data
  nd <- read_pattern(selector, colnums = seq(length(col_names)),
                     pattern = 'T')  # match T in air-trend isoformat time col

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
    # Filter and sort by time
    rename(Time_UTC = time) %>%
    dplyr::filter(!is.na(Time_UTC)) %>%
    arrange(Time_UTC)

  print_nd()
  return(nd)
}