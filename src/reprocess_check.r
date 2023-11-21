# James Mineau

reprocess_check <- function(site = get('site', envir = globalenv()),
                            site_config = get('site_config', envir = globalenv())) {

  # Identify reprocess file relevant to site
  reprocessf <- file.path('data', site, 'reprocess')

  # Proceed if reprocess file does not exist
  if (!file.exists(reprocessf)) {
    return()
  }

  # Temporarily set reprocess flag to TRUE
  site_config$reprocess <<- T

  # Remove reprocess file
  system(paste('rm', reprocessf))
}