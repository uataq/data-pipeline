read_pattern <- function(selector, colnums = NULL, pattern = NULL, ...) {
  
  # Parse colnums into format compatible with `cut -f`
  # colnums examples:
  # colnums <- NULL
  # colnums <- 1
  # colnums <- '1,2,3'
  # colnums <- c(1, 2, 3)
  if (is.null(colnums)) {
    cut_cmd <- ''
  } else {
    if (is.vector(colnums, 'numeric') || (length(colnums) > 1)) {
      colnums <- paste(colnums, collapse = ',')
    }
    cut_cmd <- paste('| cut -d \',\' -f', colnums)
  }
  
  # Parse pattern into format compatible with `grep`
  # pattern <- NULL
  # pattern <- ','
  # pattern <- '$GPGGA'
  if (is.null(pattern[1])) {
    grep_cmd <- ''
  } else {
    grep_cmd <- paste('| grep', pattern, collapse = ' ')
  }
  
  # Remove null bytes and quotes
  sed_cmd <- "| sed 's/\\x0/ /g;s/\"/ /g'"
  iconv_cmd <- '| iconv -c'
  
  cmd <- paste('cat', selector, sed_cmd, iconv_cmd, grep_cmd, cut_cmd)
  con <- pipe(cmd, 'r')
  on.exit(close(con))
  breakstr(readLines(con, skipNul = T))
}
