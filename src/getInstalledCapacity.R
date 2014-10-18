# get installed cap function

# require(stringr)
# require(plyr)
# require(reshape2)
library(tidyr)
library(lubridate)
library(magrittr)
library(stringr)

getInstalledCapacity <- function(fileName){
  # read the data
  #rawData <- read.csv("./data/installedCap/clean/pv_201101-201112_ret201212.csv")
  message(paste0("Processing: ", fileName))
  
  rawData <- read.csv(fileName)
  print(summary(rawData))
  
  # get the data source
  tmp <- str_split(fileName, "/")
  dataSource <- tmp[[1]][length(tmp[[1]])]
  
  # use tidyr
  maxCol <- ncol(rawData)
  installedCap <- rawData %>% 
    gather(key, value, -1) %>%
    separate(key, c("date", "type"), sep = "\\.\\.\\.") %>%
    spread(type, value)
  
  #=====================================================
  # this uses the plyr approach
  # get the date and type of each col from col header name
#   colNames <- names(rawData)  # first column is the postcode
#   colNameSplit <- str_split(colNames[2:length(colNames)], "\\.\\.\\.")
#   colMeta <- ldply(colNameSplit, 
#                    .fun = function(x) data.frame("date" = x[[1]], "type" = x[[2]]))
#   colMeta$id <- colNames[2:length(colNames)]
#   
#   # melt rawData and join to get date and type --> tidy data frame
#   installedCap <- melt(rawData, id.vars = 1)
#   installedCap <- merge(installedCap, colMeta, by.x = "variable", by.y = "id")
#   
#   # clean up
#   installedCap$variable <- NULL
#   installedCap <- dcast(installedCap, 
#                         Small.Unit.Installation.Postcode + date ~ type, 
#                         value.var = "value")
#   names(installedCap) <- c("Postcode", "date", "numberInstallations", "totalCapacity_kW")
#   
#   # convert data types
#   installedCap$Postcode <- as.factor(installedCap$Postcode)
#   installedCap$numberInstallations  <- as.numeric(installedCap$numberInstallations)
#   installedCap$totalCapacity_kW  <- as.numeric(installedCap$totalCapacity_kW)
  
  # clean up
  names(installedCap) <- c("Postcode", "date", "numberInstallations", "totalCapacity_kW") 

  # convert date to posix
  installedCap$date <- dmy(paste0("1.",installedCap$date))
  
  # reorder
  installedCap <- installedCap[order(installedCap$Postcode, installedCap$date),]
  
  installedCap$dataSource <- dataSource
  return(installedCap)
}


