lock_clean <- function() {
  system('rm pipeline/.lock/*')
}
