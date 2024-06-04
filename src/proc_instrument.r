#' Process an instrument
#'
#' This function executes a provided expression, which should outline the processing steps for an instrument. 
#' Typically, the expression should follow this structure:
#'
#' nd <- init_func()
#' if (!should_reprocess())
#'   update_archive(nd, data_path(site, instrument, 'raw'), check_header = F)
#' nd <- qaqc_func(nd)
#' update_archive(nd, data_path(site, instrument, 'qaqc'))
#' if (calibration_needed) {
#'   nd <- calibrate_func(nd)
#'   update_archive(nd, data_path(site, instrument, 'calibrated'))
#' }
#' nd <- finalize_func(nd)
#' update_archive(nd, data_path(site, instrument, 'final'))
#'
#'  Additional, site/instrument-specific processing steps can be injected as needed.
#'
#' @param expr An expression detailing the processing steps for an instrument.
#' @return This function doesn't return a value; it simply executes the provided expression.
#' @details Custom 'processing disabled' errors are suppressed.
#' All other errors cause the processing to stop.
#' @examples
#' expr <- expression({
#'   nd <- init_func()
#'   # ... rest of the processing steps ...
#' })
#' proc_instrument(expr)
proc_instrument <- function(expr) {
  tryCatch({
    proc_init()  # Initialize processing
    expr  # Execute expression
  }, error = function(e) {
    if (grepl("processing disabled", tolower(e$message))){
      # do nothing
      cat('')
    } else {
      message(e)
    }
  })
}
