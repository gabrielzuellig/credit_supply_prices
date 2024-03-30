/*

	3_DE_aggregated:
	
	This file loads Broda-Weinstein demand elasticities at hs6-level and aggregates
	to coarser levels of disaggregation, namely 4-digit product codes and firm-level averages 
	
	DEPENDENCIES:
	
	Inputs:
	
	 - data/5_demand_elasticities/out/cn6_byyear.dta
	   hs6 year sigmaBW sigmaBWHS
	 
	 - Files needed to determine which firms show up in PPI and UHDM:
	   $cleandatapath/PPI/out/quarterly/ppi_domestic
	   $cleandatapath/PPI/out/quarterly/ppi_exports
	   data/4_unitvalues/out/exportdata
	 
	Outputs:
	 
	 - data/5_demand_elasticities/out/cn6.dta
	   hs6 sigmaBW sigmaBWHS
	 - data/5_demand_elasticities/out/cn4.dta
	   cn4 sigmaBW sigmaBWHS	
	 - data/5_demand_elasticities/out/firmCN2lvl_DE_UHDMfirms
	   cvrnr cn2 sigmaBW_UHDM sigmaBWHS_UHDM 
	 - data/5_demand_elasticities/out/firmlvl_DE_allcvrnr
	   cvrnr sigmaBW_firmlvl
	  

*/


global path = "$projectpath/data/5_demand_elasticities"
cd $path
cap mkdir $path/out


******************************************************************************
* Time-invariant estimates of sigma at 6-digit and 4-digit levels
******************************************************************************

use $path/out/cn6_byyear, replace  // main file is at 6-digit-year level (because 6-digits codes for the same product can be re-defined over the years, even though this does not happen much)
collapse (mean) sigmaBW sigmaBWHS, by(hs6)   // average over years to get time-invariant sigma
save $path/out/cn6, replace  
gen cn4 = substr(hs6, 1, 4)
collapse (mean) sigmaBW_4dig=sigmaBW, by(cn4)  // sigma at 4-digit HS code level (will be used to substitute those that cannot be matched at 6-digits levels)
save $path/out/cn4, replace


******************************************************************************
* Firm-level estimates
******************************************************************************

** PPI firms: Get average demand elasticity for firms that are surveyed in PPI
use $cleandatapath/PPI/out/quarterly/ppi_domestic, clear
append using $cleandatapath/PPI/out/quarterly/ppi_exports
keep if tq == yq(2007,4) & nationtype == 2
gen obs_PPI = 1
merge m:1 hs6 using $path/out/cn6, keep(match master) nogen
collapse (mean) sigmaBW_PPI = sigmaBW (sum) obs_PPI, by(cvrnr)
save $path/temp/firmlvl_DE_PPIfirms, replace

** UHDM: Get weighted average demand elasticity at firm-CN2-and firm-level for firms that show up in UHDM
use $projectpath/data/4_unitvalues/out/exportdata, replace
keep if year == 2007
gen hs6 = substr(CN8, 1, 6)
merge m:1 cvrnr using $projectpath/data/3_sample/out/sample, keep(match) keepus(*UHDM*) nogen
keep cvrnr hs6 year value 
gen cn2 = substr(hs6, 1, 2)
bys cvrnr cn2: egen totalvalue_firmcn2 = total(value)
gen wgt_firmcn2 = value / totalvalue_firmcn2
bys cvrnr: egen totalvalue_firm = total(value)
gen wgt_firm = value / totalvalue_firm
merge m:1 hs6 year using $path/out/cn6_byyear, keep(match master) nogen
preserve 
gcollapse (mean) sigmaBW_UHDM = sigmaBW sigmaBWHS_UHDM = sigmaBWHS [aw=wgt_firmcn2], by(cvrnr cn2)
save $path/out/firmCN2lvl_DE_UHDMfirms, replace
restore 
gen obs_UHDM = 1
gcollapse (mean) sigmaBW_UHDM = sigmaBW (rawsum) obs_UHDM [aw=wgt_firm], by(cvrnr)
save $path/temp/firmlvl_DE_UHDMfirms, replace

** combine both firm samples
merge 1:1 cvrnr using $path/temp/firmlvl_DE_PPIfirms, nogen
sort cvrnr
qui replace obs_UHDM = 0 if obs_UHDM == .
qui replace obs_PPI = 0 if obs_PPI == .
gen sigmaBW_firmlvl =  sigmaBW_PPI  // PPI takes precedence: if firm is in both, take average sigmaBW from PPI
qui replace sigmaBW_firmlvl = sigmaBW_UHDM if obs_PPI == 0
keep cvrnr sigmaBW_firmlvl
save $path/out/firmlvl_DE_allcvrnr, replace
