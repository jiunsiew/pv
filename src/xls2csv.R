library(XLConnect)
workBook <- loadWorkbook(filename = "~/Documents/analytics/R/pv/data/installedCap/raw/original/RET-data-0914.xls")
solarData <- readWorksheet(workBook, sheet = "SGU - Solar Panels", startRow = 4)

# get rid of the previous years columns
solarData <- subset(solarData, select = c(-2,-3, -44, -45))

# save to csv
write.csv(solarData, 
          file = "./data/installedCap/raw/pv_201301-201408_ret201409.csv", 
          row.names = FALSE)
