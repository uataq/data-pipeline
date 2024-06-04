should_reprocess <- function(site = get('site', envir = globalenv()),
                             instrument = get('instrument', envir = globalenv())) {
  return(site_config$reprocess == 'TRUE'
         || instrument %in% unlist(site_config$reprocess))
}