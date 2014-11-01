# munge installed cap data

rm(list = ls())
library(plyr)
library(dplyr)

# Get installed capacity data ---------------------------------------------
# this is from the raw csv files
source("./src/getInstalledCapacity.R")

fileDir <- "./data/installedCap/raw"
fileList <- c(file.path(fileDir, "pv_200001-201012_ret201212.csv"),
              file.path(fileDir, "pv_201101-201112_ret201212.csv"),
              file.path(fileDir, "pv_201201-201212_ret201401.csv"),
              file.path(fileDir, "pv_201301-201408_ret201409.csv"))
              # file.path(fileDir, "pv_201301-201312_ret201406.csv"),
              # file.path(fileDir, "pv_201401-201405_ret201406.csv"))

installedCap <- ldply(fileList, .fun = getInstalledCapacity)
installedCap$dataSource <- as.factor(installedCap$dataSource)

# clean some known anomalies
installedCap <- filter(installedCap, Postcode > 0)  # post code = 0 

# map some state information to each postcode
postcodeDefn <- read.csv("./data/geography/clean/pc_full_lat_long.csv")

# get rid of duplicates
postcodeDefn <- postcodeDefn[!(duplicated(postcodeDefn$Postcode)), ]

# merge
installedCap <- merge(installedCap, postcodeDefn, by = "Postcode", all.x = TRUE)

# save binaries as a temp
save(installedCap, fileList,
     file = file.path("./data/installedCap/clean", 
                      paste0("installedCapacity_", Sys.Date(), ".RData" )))



