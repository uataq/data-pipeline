data_path <- function(site, instrument, lvl) {
  file.path('data', site, instrument, lvl, paste0('%Y_%m_', lvl, '.dat'))
}
