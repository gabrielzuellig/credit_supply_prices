/*

	1_GEN_PANEL:
	
	This file combines good-level PPI prices with all other firm-level data
	needed for the diff-in-diff

	DEPENDENCIES:
	
	Inputs:
	 - $cleandatapath/PPI/out/quarterly/ppi_domestic.dta
	   tq year cvrnr prisadj2 hs6 panid nationtype

	- $cleandatapath/PPI/out/quarterly/ppi_exports.dta
	   tq year cvrnr prisadj2 hs6 panid nationtype

	- $projectpath/data/3_sample/out/sample.dta
	   tt_uvall nace nace2d loans_uv07 loans_uv06 loans_to_revenue07 deposits_to_revenue07 stshare07 interest_rate07 
	   emp07 lemp07 revenue07 lrevenue07 equity_share07 profit_to_revenue07 ms_4d07 avg_wage07 
	   firmage04 connections_loans07 connections_deposits07 inv_to_revenue07 pbshare07 wk_to_revenue07

	- $projectpath/data/5_demand_elasticities/out/cn6.dta
	  sigmaBW sigmaBWHS
	 
	- $projectpath/data/5_demand_elasticities/out/cn4.dta
	  sigmaBW_4dig
	  
	- $projectpath/data/5_demand_elasticities/out/cn2.dta
	  betaSC_w
	 
	Outputs:
	 - analysis/3_did_ppi/temp/panel (good-quarter-level), ready for diff-in-diff estimations
	   used in 2_did_ppi and 3_did_ppi_heterogeneity

*/


global path = "$projectpath/analysis/3_did_ppi"
cd $path
cap mkdir $path/out
cap mkdir $path/temp


********************************************************************************
* 1. start with ppi data (domestic + exports), product-level
********************************************************************************

use $cleandatapath/PPI/out/quarterly/ppi_domestic, clear
append using $cleandatapath/PPI/out/quarterly/ppi_exports
drop if !inrange(year, 2003, 2015)
keep tq year cvrnr prisadj2 hs6 panid nationtype


********************************************************************************
* 2. merge demand elasticities, product-level
********************************************************************************

* merge estimated demand elasticities at 6-digit-level
merge m:1 hs6 using $projectpath/data/5_demand_elasticities/out/cn6, keep(match master) nogen
sum sigmaBW if inrange(year, 2005, 2012) // 90,935 obs. (94%)
sum sigmaBWHS if inrange(year, 2005, 2012)  // 83,520 obs.
* there are still some missing (hs6 match but have no BW estimate). merge those based on cn4.
gen cn4 = substr(hs6, 1, 4)
merge m:1 cn4 using $projectpath/data/5_demand_elasticities/out/cn4, keep(match master) nogen
replace sigmaBW = sigmaBW_4dig if sigmaBW == . // 95,614
* merge estimated strategic complementarities at 2-digit level
gen cn2 = substr(hs6, 1, 2)
merge m:1 cn2 using $projectpath/data/5_demand_elasticities/out/cn2, keep(match master) keepus(betaSC_w) nogen


********************************************************************************
* 3. merge  firm sample
********************************************************************************

merge m:1 cvrnr using $projectpath/data/3_sample/out/sample, keep(match) keepus(tt_uvall nace nace2d loans_uv07 loans_uv06 loans_to_revenue07 deposits_to_revenue07 stshare07 interest_rate07 emp07 lemp07 revenue07 lrevenue07 equity_share07 profit_to_revenue07 ms_4d07 avg_wage07 firmage04 connections_loans07 connections_deposits07 inv_to_revenue07 pbshare07 wk_to_revenue07) nogen


********************************************************************************
* 4. Miscellaneous
********************************************************************************

* log price index
cap gen lprisadj2 = log(prisadj2)

* time periods
gen th = yh(year,halfyear(dofq(tq)))
cap drop period
gen period = 0
replace period = 1 if year == 2008
replace period = 2 if year>2008 & !mi(period)
label def periodlbl 0 "Pre" 1 "2008" 2 "2009 - 2010", replace
label values period periodlbl
label def y 2008 "2008" 2009 "2009" 2010 "2010", replace
label values year y

* continuous products
cap drop has*
gegen has_2004 = max((year==2004)), by(panid)
gegen has_2005 = max((year==2005)), by(panid)
gegen has_2006 = max((year==2006)), by(panid)
gegen has_2007 = max((year==2007)), by(panid)
gegen has_2008 = max((year==2008)), by(panid)
gegen has_2009 = max((year==2009)), by(panid)
gegen has_2010 = max((year==2010)), by(panid)
gegen has_2011 = max((year==2011)), by(panid)
gegen has_2012 = max((year==2012)), by(panid)

* destring
gegen firmid = group(cvrnr)
destring cvrnr, replace
replace hs = substr(hs,1,6)
destring cn4 cn2, replace

save $path/temp/panel, replace
