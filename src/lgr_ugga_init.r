lgr_ugga_init <- function() {
  
  if (!site_config$reprocess) {
    remote <- paste0('lgr@', site_config$ip, ':/home/lgr/data/')
    local <- file.path('data', site, instrument, 'raw/')
    rsync(from = remote, to = local, port = site_config$port)
  }
  
  # Unzip necessary compressed archives
  dir(file.path('data', site, instrument, 'raw'), '\\.{1}txt\\.{1}zip',
      full.names = T, recursive = T) %>%
    lapply(function(zf) {
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
  
  # Sort by file modification time since older versions of LGR's software
  # are named non-sequentially
  files <- dir(file.path('data', site, instrument, 'raw'), 'f....\\.{1}txt$',
               full.names = T, recursive = T)
  files <- files[order(file.mtime(files))]
  
  N <- ifelse(site_config$reprocess, Inf, 2)
  files <- tail(files, N)
  
  nd <- lapply(files, function(file) {
    # Catch change in number of columns in different model LGRs
    col_names <- data_config[[instrument]]$raw$col_names
    col_types <- data_config[[instrument]]$raw$col_types
    ndelim <- str_count(system(paste('head -n 2', file, '| tail -n 1'), 
                               intern = T), ',')
    if (length(ndelim) == 0) return()
    if (ndelim == 23) {
      col_names <- append(col_names, 'fillvalue', after = 22)
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
      df[[23]] <- NULL
    setNames(df, data_config[[instrument]]$raw$col_names)
  }) %>%
    bind_rows()
  
  nd$Time_UTC <- as.POSIXct(nd$Time_UTC, tz = 'UTC',
                            format = '%m/%d/%Y %H:%M:%S')
  nd <- nd %>%
    dplyr::filter(!is.na(Time_UTC)) %>%
    arrange(Time_UTC)
  
  message('New data:')
  str(nd)
  
  nd
}
