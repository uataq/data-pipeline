reset <- function(wd) {
  for (path in c('parsed', 'calibrated')) {
    system(paste('rm -r', file.path(wd, path)))
    dir.create(file.path(wd, path), showWarnings = FALSE, recursive = TRUE, mode = '0755')
  }
}
