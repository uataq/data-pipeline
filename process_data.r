#! /uufs/chpc.utah.edu/sys/installdir/R/3.4.1i/bin/R
# Ben Fasoli

setwd('/uufs/chpc.utah.edu/common/home/lin-group2/measurements-beta')

# Package dependencies
# Load required packages from self-maintained R package repository
lib <- '/uufs/chpc.utah.edu/common/home/u0791983/.Rpackages'
library(dplyr,    lib.loc = lib)
library(fasttime, lib.loc = lib)
library(readr,    lib.loc = lib)
library(uataq,    lib.loc = lib)

# Function dependencies
# Source code placed in proc/src sourced to global environment
invisible(lapply(dir('proc/src', pattern = '\\.r', full.names = T), source))

# Configuration
# Load configuration files 
sites            <- read_json('proc/config/sites.json')
data_structure   <- read_json('proc/config/data_structure.json')
global_reprocess <- F

site <- sites$lgn

