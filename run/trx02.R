# Ben Fasoli
library(uataq)

inst <- c('gps', 'met', 'metone')
nf   <- 1   # NULL for all

reset <- F

if(reset){
  nf <- NULL
  system(paste('rm -r', paste0('data/', c('parsed', 'map'), '/*', collapse=' ')))
  system(paste('mkdir', paste0('data/parsed/', inst, collapse=' ')))
}

# FUNCTIONS -------------------------------------------------------------------
# Universal read function to get instrument data
read <- function(inst, nf=1, pattern='.*\\.{1}dat') {
  hdr <- switch(inst,
                'gps'    = c('Time_common', 'NMEA_ID', 'fixtime', 'lat', 'NS', 'lon', 'EW',
                             'quality', 'nsat', 'hordilut','alt', 'alt_unit', 'geoidht', 'geoidht_unit',
                             'DGPS_id','checksum'),
                'metone' = c('Time_common', 'PM25_ugm3', 'flow_lpm', 'T_C', 'RH_pct', 'P_hPa', 'unk', 'code'),
                'met'    = c('Time_common', 'case_T_C', 'case_RH_pct', 'case_T2_C', 'case_P_hPa',
                             'amb_T_C', 'amb_RH_pct', 'box_T_C'))
  
  fpath <- file.path('data', 'raw', inst)
  files <- dir(fpath, pattern=pattern, full.names=T)
  if(!is.null(nf)) files <- tail(files, nf)
  
  raw <- do.call('c',
                 lapply(files,
                        function(x){
                          try({
                            readLines(x, skipNul=T)
                          })
                        })
  )
  
  data <- uataq::breakstr(raw)
  colnames(data) <- hdr
  for(col in 2:ncol(data)) data[ ,col] <- as.numeric(data[ ,col])
  
  if(nrow(data) < 1) return(NULL)
  
  data$Time_common <- as.POSIXct(data$Time_common, tz='UTC', format='%Y-%m-%d %H:%M:%S')
  data
}



# Parse and archive data ------------------------------------------------------
d        <- lapply(inst, read, nf=nf)
names(d) <- inst

d$metone$PM25_ugm3 <- d$metone$PM25_ugm3 * 1000
d$gps$lat <- with(d$gps, floor(lat/100)+(lat-floor(lat/100)*100)/60)
d$gps$lon <- with(d$gps, -(floor(lon/100)+(lon-floor(lon/100)*100)/60))

for(i in inst){
  archive(d[[i]], type=i, path=file.path('data', 'parsed', i))
}

# Linear interpolation --------------------------------------------------------
trax <- rbind_list(
  d$metone[c('Time_common', 'PM25_ugm3')],
  d$gps[c('Time_common', 'lat', 'lon', 'alt')],
  d$met[c('Time_common', 'case_T_C', 'case_RH_pct','case_P_hPa', 'amb_T_C', 'amb_RH_pct', 'box_T_C')]) %>%
  arrange(Time_common) %>%
  rename(Time_UTC = Time_common)

trax.interp <- cbind(Time_common = trax$Time_common, 
                     as_data_frame(
                       lapply(trax[ ,2:ncol(trax)], uataq::na_interp, x=trax$Time_common)))

archive(trax.interp, type='geo', path=file.path('data', 'map'))

trax.interp <- subset(trax.interp, Time_common > Sys.time() - 3600 * 200)
if(nrow(trax.interp) > 0){
  saveRDS(trax.interp, file.path('data', 'recent.rds'))
}

q('no')