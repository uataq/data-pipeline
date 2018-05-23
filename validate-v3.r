# Ben Fasoli
rm(list = ls())

library(fst)
library(tidyverse)

data_base_dir <- '~/../lin-group2/measurements-beta/data'

stid <- 'sug'
inst <- 'licor_6262'
lvl <- 'calibrated'

data_dir <- file.path(data_base_dir, stid, inst)

path_fst <- file.path(data_dir, paste0(lvl, '.fst'))
data_fst <- read_fst(path_fst)


path_csv <- dir(file.path(data_dir, lvl), full.names = T)
col_types <- 'Tddddddddd'
data_csv <- path_csv %>%
  lapply(read_csv, col_types = col_types, locale = locale(tz = 'UTC')) %>%
  bind_rows()

str(data_fst)
str(data_csv)

all.equal(data_fst, 
          data_csv %>% as.data.frame())


dup <- which(duplicated(data_csv$Time_UTC))
# which(duplicated(data_fst$Time_UTC))

dup[1]
View(data_csv[(dup[1]-100):(dup[1]+100),])
