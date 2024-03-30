/*

	1_GEN_PANEL:
	
	This file combines good-category-level export unit values with all other firm-level data
	needed for the diff-in-diff

	DEPENDENCIES:
	
	Inputs:
	- $projectpath/data/4_unitvalues/out/uv_all.dta
	   year cvrnr luv1 Duv1 value panid cn2

	- $projectpath/data/3_sample/out/sample.dta
	   tt_uvall nace nace2d loans_uv07 loans_uv06 loans_to_revenue07 deposits_to_revenue07 stshare07 interest_rate07 
	   emp07 lemp07 revenue07 lrevenue07 equity_share07 profit_to_revenue07 ms_4d07 avg_wage07 
	   firmage04 connections_loans07 connections_deposits07 inv_to_revenue07 pbshare07 wk_to_revenue07

	- $projectpath/data/5_demand_elasticities/out/firmCN2lvl_DE_UHDMfirms.dta
	  sigmaBW_UHDM
	  
	- $projectpath/data/5_demand_elasticities/out/cn2.dta
	  betaSC_w    
	 
	Outputs:
	 - analysis/4_did_uhdm/temp/panel (good category-year-level), ready for diff-in-diff estimations
	   used in 2_did_uhdm and 3_did_uhdm_heterogeneity

*/


global path = "$projectpath/analysis/4_did_uhdm"
cd $path
cap mkdir out
cap mkdir temp


********************************************************************************
* 1. load data
********************************************************************************

use $projectpath/data/4_unitvalues/out/uv_all, clear
drop if !inrange(year, 2003, 2015)
keep year cvrnr luv1 Duv1 value CN2 
rename CN2 cn2
egen panid = group(cvrnr cn2)
xtset panid year 


********************************************************************************
* 2. merge  firm sample
********************************************************************************

merge m:1 cvrnr using $projectpath/data/3_sample/out/sample.dta, keep(match) keepus(tt_uvall nace nace2d loans_uv07 loans_uv06 loans_to_revenue07 deposits_to_revenue07 stshare07 interest_rate07 emp07 lemp07 revenue07 lrevenue07 equity_share07 profit_to_revenue07 ms_4d07 avg_wage07 firmage04 connections_loans07 connections_deposits07 inv_to_revenue07 pbshare07 wk_to_revenue07) nogen


********************************************************************************
* 3. Miscellaneous
********************************************************************************

merge m:1 cvrnr year using $projectpath/data/3_sample/out/panel, keep(match master) nogen

// for the price to be considered, we want there to be sales of > 10000DKK in each year
cap drop has_20*
foreach yy of numlist 2004(1)2012{
	gegen has_`yy' = max((year==`yy')*(value>10000)), by(panid)
}
gegen value07 = total(value*(year==2007)), by(panid)
gen lvalue07 = log(value07)

label def y 2008 "2008" 2009 "2009" 2010 "2010", replace
label values year y


********************************************************************************
* 4. merge demand elasticities, product level
********************************************************************************

merge m:1 cvrnr cn2 using $projectpath/data/5_demand_elasticities/out/firmCN2lvl_DE_UHDMfirms, keep(match master) nogen
rename sigmaBW_UHDM sigmaBW
merge m:1 cn2 using $projectpath/data/5_demand_elasticities/out/cn2, keep(match master) keepus(betaSC_w) nogen

compress
save $path/temp/panel, replace
