lgr_ugga_init <- function() {

  pattern <- 'f....\\.{1}txt'
  datetime_format <- '%m/%d/%Y %H:%M:%S'

  wd <- file.path('data', site, instrument, 'raw')

  # Call list.files once to minimize time spent in system calls
  files <- list.files(wd, pattern = pattern,
                      full.names = T, recursive = T)

  # Sort by file modification time since older versions of LGR's software
  # are named non-sequentially
  files <- files[order(file.mtime(files))]

  if (!should_reprocess()) {
    # Get last time of data in site/instrument/raw directory
    last_txt_file <- tail(grep('\\.txt$', files, value = T), 1)
    if (length(last_txt_file) == 0) {
      warning('No prior data found: ', wd)
      last_time <- as.POSIXct('1970-01-01', tz = 'UTC')
    } else {
      last_time <- get_last_time(last_txt_file, format = datetime_format)
      if (is.null(last_time)) {
        # If last_time is NULL, read in last two days of data
        last_time <- Sys.Date() - 1
      }
    }

    # Rsync data from remote
    remote <- paste0('lgr@', site_config$ip, ':/home/lgr/data/')
    local <- file.path(wd, '')
    modified_files <- rsync(from = remote, to = local, port = site_config$port,
                            return.files = T)

    # Append modified files to list of files, removing duplicates
    files <- c(files,
               file.path(wd, grep(pattern, modified_files, value = T))) %>%
      unique()

    n_files <- length(seq(as.Date(last_time), Sys.Date(), by = 'day'))
  } else {
    # TODO: at some point we need to process in batches to avoid memory issues
    n_files <- Inf
  }

  # Split files into txt and zip files
  zip_files <- grep('\\.{1}zip$', files, value = T)
  files <- setdiff(files, zip_files)

  # Unzip necessary compressed archives
  lapply(zip_files, function(zf) {
    tf <- tools::file_path_sans_ext(zf)
    if (file.exists(tf) &&
        (abs(as.numeric(file.mtime(tf)) - as.numeric(file.mtime(zf))) < 1)) {
      return()
    } else {
      # If the ASCII .txt file does not exist or the modified time does not
      # match that of the .zip file, overwrite the text file with data from 
      # the .zip file and update the modified times of the two
      invisible({
        system(paste('unzip -o', zf, '-d', dirname(zf)),
                ignore.stdout = T, ignore.stderr = T)
        system(paste('touch', zf, tf))
      })
    }
  }) %>%
    invisible()

  # Read in data
  nd <- lapply(tail(files, n_files), function(file) {
    print(paste('Reading:', file))
    # Catch change in number of columns in different model LGRs
    col_names <- data_config[[instrument]]$raw$col_names
    col_types <- data_config[[instrument]]$raw$col_types
    ndelim <- str_count(system(paste('head -n 2', file, '| tail -n 1'),
                               intern = T), ',')
    if (length(ndelim) == 0) return()
    if (ndelim == 23) {
      col_names <- append(col_names, 'MIU_Valve', after = 22)
      col_types <- paste0(col_types, 'c')
    }
    df <- tryCatch(suppressWarnings({
      read_csv(file, col_names = col_names, col_types = col_types, skip = 2,
               na = c('TO', '', 'NA'), progress = F)
    }),
    error = function(e) NULL)

    if (is.null(df) || ncol(df) < 23 || ncol(df) > 24) return(NULL)

    # Adapt column names depending on LGR software version.
    #  2013-2014 version has 23 columns
    #  2014+ version has 24 columns (MIU split into valve and description)
    if (ncol(df) == 24)
      df[[23]] <- NULL  # remove MIU_Valve column 
    setNames(df, data_config[[instrument]]$raw$col_names)
  }) %>%
    bind_rows()

  nd$Time_UTC <- as.POSIXct(nd$Time_UTC, tz = 'UTC',
                            format = datetime_format)

  # Format time
  nd <- nd %>%
    dplyr::filter(!is.na(Time_UTC),
           # Timezone America/Denver to UTC shift
           # Data during 12-29-2015 to 12-30-2015 invalid due to shift on day
           Time_UTC < as.POSIXct('2015-12-29', tz = 'UTC') |
             Time_UTC > as.POSIXct('2015-12-30', tz = 'UTC')) %>%
    mutate(Time_UTC = ifelse(Time_UTC < as.POSIXct('2015-12-30', tz = 'UTC'),
                             as.POSIXct(format(Time_UTC, tz = 'UTC'),
                                        tz = 'America/Denver'),
                             Time_UTC))
  attributes(nd$Time_UTC) <- list(class = c('POSIXct', 'POSIXt'),
                                  tzone = 'UTC')
  nd <- nd %>%
    arrange(Time_UTC)

  print_nd()
  return(nd)
}
