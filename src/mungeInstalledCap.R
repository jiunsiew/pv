# munge installed cap data

rm(list = ls())
library(plyr)

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

# save binaries as a temp
save(installedCap, fileList,
     file = file.path("./data/installedCap/clean", 
                      paste0("installedCapacity_", Sys.Date(), ".RData" )))


# Add postcodes and region ------------------------------------------------
library(dplyr)
poa.df <- tbl_df(read.csv("./data/absGeography/raw/POA_2011_AUST.csv"))  # the Postcode to SA1 map
sa1.df <- tbl_df(read.csv("./data/absGeography/raw/SA1_2011_AUST.csv"))  # the sa1 to region map

poaSa1 <- tbl_df(merge(poa.df[, c("SA1_MAINCODE_2011", "POA_CODE_2011", "AREA_ALBERS_SQKM")],
                       sa1.df[, c("SA1_MAINCODE_2011", "SA2_MAINCODE_2011", "SA2_NAME_2011", 
                                  "STATE_CODE_2011", "STATE_NAME_2011")],
                       by = "SA1_MAINCODE_2011"))

# summarise --> get total area of postal codes
poaSa1.summary <- poaSa1 %>% 
  group_by(POA_CODE_2011, SA2_NAME_2011, STATE_NAME_2011) %>%
  summarise(totalArea = sum(AREA_ALBERS_SQKM))
  
## NOTE: there are postcodes that straddle multiple states:
# 872 2540 2618 2620 3585 3644 4383 4825 9494 9797
# 2540 includes NSW and "other territories" --> can classify as NSW as is dominated by NSW
# 2618 and 2620 include NSW and ACT --> can classify as NSW as is dominated by NSW
# 3585 includes both NSW and VIC --> can classsify 3585 as VIC as it dominates land size
# 3644 includes both NSW and VIC --> about equal land size but VIC has higher SA1 areas.
# 4383 is NSW and QLD
# 4825 is QLD and NT
# 0872 is SA, NT and WA
# 9494 and 9497 have all regions but no installed cap data

# some installed capacity postcodes are also PO Boxes and don't exist in the ABS data
pcCheck1 <- tmp$Postcode %in% poaSa1.summary$POA_CODE_2011
missingPc <- sort(unique(tmp$Postcode[!pcCheck1]))  # postcodes that exist in the installed cap data but not in the ABS data
pcCheck2 <- poaSa1.summary$POA_CODE_2011 %in% tmp$Postcode
missingPc2 <- sort(unique(poaSa1.summary$POA_CODE_2011[!pcCheck2]))  # postcodes that exists in the ABS but not in the installed cap data

## NOTE:
# missingPc tend to be post office boxes 
# check how much installed capacity is registered at these PO boxes
missingPcTotalInstCap <- subset(tmp, Postcode %in% missingPc) %>%
  group_by(Postcode) %>%
  summarise(installedCap = sum(totalCapacity_kW),
            nInstallations = sum(numberInstallations))
# postcode with highest installed capacity is Norfolk Island (2899) ~1.6MW/541 installations -- this is in the albury area


# missingPc2 tend to be delivery areas (e.g. 3800 is monash uni)

# merge postcodes to states
tmp <- installedCap
tmp$Postcode <- as.numeric(as.character(tmp$Postcode))
installedCap.df <- tbl_df(merge(tmp, 
                                poaSa1.summary, 
                                by.x = "Postcode", by.y = "POA_CODE_2011",
                                all.x = T))
