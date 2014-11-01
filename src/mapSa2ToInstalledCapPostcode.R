#' add SA2 level information to installed capacity
#' this isn't a perfect science as some postcodes overlap
#' 

load("./data/installedCap/clean/installedCapacity_2014-06-28.RData")

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
pcCheck1 <- installedCap$Postcode %in% poaSa1.summary$POA_CODE_2011
missingPc <- sort(unique(installedCap$Postcode[!pcCheck1]))  # postcodes that exist in the installed cap data but not in the ABS data
pcCheck2 <- poaSa1.summary$POA_CODE_2011 %in% installedCap$Postcode
missingPc2 <- sort(unique(poaSa1.summary$POA_CODE_2011[!pcCheck2]))  # postcodes that exists in the ABS but not in the installed cap data

## NOTE:
# missingPc tend to be post office boxes 
# check how much installed capacity is registered at these PO boxes
missingPcTotalInstCap <- installedCap %>% filter(Postcode %in% missingPc) %>%
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