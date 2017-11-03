get_file_header <- function(file) {
  
  if (!file.exists(file))
    stop('File ', file, ' does not exist')
  
  return(unlist(strsplit(',', readLines(file, n = 1))))
}