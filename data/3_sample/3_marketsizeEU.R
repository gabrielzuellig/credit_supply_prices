############################################################################################
#
#  3_MARKETSIZEEU.R
#
#  This script reads PRODCOM statistics for the years 2005-16 and calculates, for each
#  prodcode/industry total sales in the EU28 and in Denmark.
#
#  DEPENDENCIES:
#  
#  Inputs:
#   
#   - R packages gdata, readxl, data.table and foreign
#
#   - in/PRODCOM/Website_snapshat_2005_N2.xlsx - in/PRODCOM/Website_snapshat_2016_N2.xlsx
#     varlist needed: PRODCOM Code, Value EU28, Denmark  
#
#  Output:
#  
#   - temp/marketsize.dta
#     varlist: nace year market_EU28

############################################################################################


library(gdata)
library(readxl)
library(data.table)
library(foreign)

## Load prodcom (main data source)
ms <- data.frame('NA',1,1,1)
colnames(ms) <- c('prodcode','val_EU28','val_DK','year')

for (yy in c(2005:2016)){   # loop over years 2005-16
  
  print(yy)
  prodcom <- read.xls(paste0('../5_demand_elasticities/in/PRODCOM/Website_snapshot_',yy,'_N2.xlsx'))
  for (k in 1:ncol(prodcom)){
    prodcom[,k] <- as.character(prodcom[,k])
  }
  colnames(prodcom) <- unlist(c(prodcom[2,]))  # column names should be countries in 2nd row
  prodcom <- prodcom[6:nrow(prodcom), c(1, which(prodcom[2,] %in% c('Value EU28','Denmark')))]  # get values for EU28 and DK
  for (k in 2:ncol(prodcom)){
    prodcom[,k] <- as.numeric(prodcom[,k])
    prodcom[is.na(prodcom[,k]), k] <- 0
  }
  colnames(prodcom)[which(colnames(prodcom) == 'PRODCOM Code')] <- 'prodcode'
  colnames(prodcom)[which(colnames(prodcom) == 'Value EU28')] <- 'val_EU28' # values in 1000 EUR
  colnames(prodcom)[which(colnames(prodcom) == 'Denmark')] <- 'val_DK'
  prodcom$year <- yy
  ms <- rbind(ms, prodcom)
  rm(prodcom)

}
ms <- ms[2:nrow(ms), ]

## Aggregate from 8-digit prodcode x year to 4-digit x year
ms$prodcode <- as.character(ms$prodcode)
ms$nace <- as.numeric(substr(ms$prodcode, 1, 4))
ms <- data.table(ms)
ms <- ms[, j=list(val_EU28 = sum(val_EU28),
                  val_DK = sum(val_DK)), 
         by=list(nace,year)]
ms <- data.frame(ms[order(ms$nace, ms$year), ])

## convert exchange rate for euro area output to DKK
E <- data.frame(year = c(2005:2016))
E$E <- c(7.451927, 7.4591, 7.450551,	7.455974,	7.446251,	7.447366,	7.450529,
         7.443751,	7.457982,	7.454741,	7.458572,	7.445238)
ms <- merge(ms, E, by=c('year'), all.x=T)
summary(ms$E, useNA='always')
ms$market_EU28 <- ms$val_EU28 * ms$E
  
## export
ms <- ms[, c('nace','year','market_EU28')]
ms <- ms[order(ms$nace, ms$year), ]
write.csv(ms, 'temp/marketsize.csv', row.names=F)
write.dta(ms, 'temp/marketsize.dta')
rm(ms, E, k, yy)
