lgr_ugga_init <- function() {

  if (site_info[[site]]$reprocess) {
    # Read all historic raw data into memory as new data
    files <- dir(file.path('data', site, instrument, 'raw'),
                 pattern = 'f....\\.{1}txt$', full.names = T, recursive = T)
    return(read_files(files,
                      col_names = data_info[[instrument]]$raw$col_names,
                      col_types = data_info[[instrument]]$raw$col_types))
  }

  remote <- paste0('lgr@', site_info[[site]][[instrument]]$ip,
                   ':/home/lgr/data/')
  local <- file.path('data', site, instrument, 'raw/')
  rsync(from = remote, to = local, port = site_info[[site]][[instrument]]$port)

  # Unzip necessary compressed archives
  dir(file.path('data', site, instrument, 'raw'), '\\.{1}txt\\.{1}zip',
      full.names = T, recursive = T) %>%
    lapply(function(zf) {
      tf <- tools::file_path_sans_ext(zf)
      if (file.exists(tf) && round(file.mtime(zf)) == round(file.mtime(tf))) {
        return()
      } else {
        # If the ASCII .txt file does not exist or the modified time does not
        # match that of the .zip file, overwrite the text file with data from the
        # .zip file and update the modified times of the two
        system(paste('unzip -o', zf, '-d', dirname(zf)))
        system(paste('touch', zf, tf))
      }
    }) %>%
    invisible()

  # Sort by file modification time since older versions of LGR's software
  # are named non-sequentially
  files <- dir(file.path('data', site, instrument, 'raw'), 'f....\\.{1}txt$',
            full.names = T, recursive = T)
  files <- files[order(file.mtime(files))]
  files <- tail(files, 2)

  nd <- lapply(files, function(file) {
    df <- tryCatch(suppressWarnings(
      read_csv(file, col_names = F, skip = 2, na = c('TO', '', 'NA'),
               locale = locale(tz = 'UTC'))),
      error = function(e) NULL)

    if (is.null(df) || ncol(df) < 23 || ncol(df) > 24) return(NULL)

    # Adapt column names depending on LGR software version.
    #  2013-2014 version has 23 columns
    #  2014+ version has 24 columns (MIU split into valve and description)
    if (ncol(df) == 24)
      df[[23]] <- NULL
    setNames(df, data_info[[instrument]]$raw$col_names)
  }) %>%
    bind_rows()

  nd$Time_UTC <- fastPOSIXct(nd$TIMESTAMP, tz = 'UTC',
                             format = '%m/%d/%Y %H:%M:%S')
  nd <- nd %>%
    dplyr::filter(!is.na(Time_UTC), !is.na(ID)) %>%
    arrange(Time_UTC)

  nd
}
