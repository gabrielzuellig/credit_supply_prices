/*

	2_DE_prepare_broda_weinstein:
	
	This file loads Broda-Weinstein demand elasticities and merges them onto
	the products in the two price samples (whereby a translation of SITC to HS
	codes is necessary). The main variable of interest is sigmaBW (demand elasticity
	by SITC codes for estimated on US imports 1990-2000); as a robustness we use
	sigmaBWHS (which is directly estimated for HS codes but has a lower match share)

	DEPENDENCIES:
	
	Inputs:
	 - data/5_demand_elasticities/in/ElasticitiesBrodaWeinstein90-01_SITCRev3_4-digit.txt
	   sitcrev34digit (=sitc3_4d) sigma19902001 (=sigmaBW)
	   
	 - data/5_demand_elasticities/in/CN6_SITC3.txt 
	   hs6 sitc3_4d
	 
	 - price data, just in order to check which product codes we need
	     $cleandatapath/PPI/out/quarterly/ppi_domestic
	     $cleandatapath/PPI/out/quarterly/ppi_exports
	     year hs (8-digit HS codes in raw PPI data)
	     $projectpath/data/4_unitvalues/out/exportdata
	     year CN8 (8-digit HS codes in raw UHDM data)
	   
	 - $projectpath/data/4_unitvalues/temp/complete_mapping
	 
	 - data/5_demand_elasticities/in/ElasticitiesBrodaWeinstein90-01_HTS-3.csv
	   hs10 (=>hs6) sigmaBWHS
	 
	Outputs:
	 
	 - data/5_demand_elasticities/out/cn6_byyear
	   hs6 year sigmaBW sigmaBWHS
	   For each HS6 code that shows up in any of our price data, we have sigmaBW 
	   and sigmaBWHS

*/

global path = "$projectpath/data/5_demand_elasticities"
cd $path
cap mkdir $path/out


******************************************************************************
* BRODA-WEINSTEIN BY SITC (higher coverage despite not exactly matching hs codes)
******************************************************************************

// 1. Match Broda-Weinstein demand elasticities to CN6-2017
import delimited "${path}/in/ElasticitiesBrodaWeinstein90-01_SITCRev3_4-digit.txt", clear
gen sitc3_4d = string(sitcrev34digit, "%04.0f")
rename sigma19902001 sigmaBW
keep sitc3* sigmaBW
save $path/temp/BW06_sitc4, replace
gen sitc3_3d = substr(sitc3_4d, 1, 3)
collapse (mean) sigmaBW, by(sitc3_3d)
save $path/temp/BW06_sitc3, replace

import delimited "${path}/in/CN6_SITC3.txt", stringc(_all) clear
rename (v1 v2) (hs6 sitc3_4d)
// merge sigmaBW onto all HS6-codes if they match to a 4-digit SITC codes (>90%)
merge m:1 sitc3_4d using $path/temp/BW06_sitc4, keep(match master) nogen
gen sitc3_3d = sitc3_4d if length(sitc3_4d) == 3
// if match is not possible on 4-digit SITC, try on 3-digit
merge m:1 sitc3_3d using $path/temp/BW06_sitc3, keep(match master match_up) update nogen
sort sitc3_4d
drop sitc3_3d
save $path/temp/BW06_cn, replace

// 2. Match CN6 that show up in any of our price data to CN6-2017 
use $cleandatapath/PPI/out/quarterly/ppi_domestic, clear
append using $cleandatapath/PPI/out/quarterly/ppi_exports
keep year hs
gen inPPI = 1
append using $projectpath/data/4_unitvalues/out/exportdata, gen(inUHDM)
gen source = "PPI" if inPPI == 1 
replace source = "UHDM" if inUHDM == 1 
replace CN8 = hs if source == "PPI"
collapse (count) unit, by(year CN8)
keep year CN8 
keep if year >= 2005  // all CN8 codes that we have in any data. try to match SITC3 5-digit 
save $path/temp/allCN8, replace

// loop over all year_orig
forvalues yy = 2005/2012 {
use $path/temp/allCN8, replace
keep if year == `yy' 
gen CN8_orig = CN8 
gen year_org = year
rename (year CN8) (year_1 CN8_1)
local yymin = `yy'+1
forvalues yyy = `yymin'/2017{ // iterate translation codes forward to 2017
    disp `yyy'
	distinct CN8_orig
	joinby CN8_1 year_1 using $projectpath/data/4_unitvalues/temp/complete_mapping, unmatched(master)
	qui replace CN8_2 = CN8_1 if CN8_2 == ""
	keep CN8_orig CN8_2 year_2
	rename (CN8_2 year_2) (CN8_1 year_1)
	qui replace year_1 = `yyy'
}
distinct CN8_orig
rename CN8_1 CN8_2017
sort CN8_orig CN8_2017
drop year_1
gen year_orig = `yy'
save "$path/temp/CN8_mappings/CN8_transl_`yy'_17", replace
}

// combine orig_year vintages
use $path/temp/CN8_mappings/CN8_transl_2005_17, replace
forvalues yy = 2006/2012 {
    append using "$path/temp/CN8_mappings/CN8_transl_`yy'_17"
}
gen hs6_orig = substr(CN8_orig, 1, 6)
gen hs6 = substr(CN8_2017, 1, 6)
gen one = 1
collapse (count) one, by(hs6_orig hs6 year_orig) // uniqueness for hs6-hs6_2017 

// 3. Merge Broda/Weinstein elasticities on CN6 (year-specific as they show up in our data)
merge m:1 hs6 using $path/temp/BW06_cn, keep(match master)
collapse (mean) sigma* (firstnm) sitc3_4d, by(hs6_orig year)
save $path/temp/cn6_byyear, replace


******************************************************************************
* BRODA-WEINSTEIN BY HTS 
******************************************************************************

// 1. Read in broda-weinstein table
import delimited $path/in/ElasticitiesBrodaWeinstein90-01_HTS-3.csv, clear
drop v3 v4
drop if _n <= 4
gen hs10 = string(real(v1), "%010.0f")
destring v2, gen(sigmaBWHS)
drop if sigmaBWHS == .
drop v1 v2 
gen hs6 = substr(hs10, 1, 6)  // only half the ppi sample matches at hs8-level, so need to reduce it further to 6-digit
distinct hs10 hs6
collapse (mean) sigmaBWHS, by(hs6)
save $path/temp/BW06_hts, replace

// 2. Match CN6 that show up in any of our price data to CN6-2017 
forvalues yy = 2005/2012 {
use $path/temp/allCN8, replace
keep if year == `yy' 
gen CN8_orig = CN8 
gen year_org = year
rename (year CN8) (year_2 CN8_2)
local yymin = `yy'-1
forvalues yyy = `yymin'(-1)2001 { // iterate translation codes forward to 2017
    disp `yyy'
	distinct CN8_orig
	joinby CN8_2 year_2 using $projectpath/data/4_unitvalues/temp/complete_mapping, unmatched(master)
	qui replace CN8_1 = CN8_2 if CN8_1 == ""
	keep CN8_orig CN8_1 year_1
	rename (CN8_1 year_1) (CN8_2 year_2)
	qui replace year_2 = `yyy'
}
distinct CN8_orig
rename CN8_2 CN8_2001
sort CN8_orig CN8_2001
drop year_2
gen year_orig = `yy'
save "$path/temp/CN8_mappings/CN8_transl_`yy'_01", replace
}

// combine orig_year vintages
use $path/temp/CN8_mappings/CN8_transl_2005_01, replace
forvalues yy = 2006/2012 {
    append using "$path/temp/CN8_mappings/CN8_transl_`yy'_01"
}
gen hs6_orig = substr(CN8_orig, 1, 6)
gen hs6 = substr(CN8_2001, 1, 6)
gen one = 1
collapse (count) one, by(hs6_orig hs6 year_orig) // uniqueness for hs6-hs6_2017 

// 3. Merge Broda/Weinstein elasticities on CN6 (year-specific as they show up in our data)
merge m:1 hs6 using $path/temp/BW06_hts, keep(match master)
tab hs6 if sigmaBWHS == .  // these sitc's actually have no estimated demand elastiity
collapse (mean) sigma*, by(hs6_orig year)
merge 1:1 hs6_orig year using $path/temp/cn6_byyear, nogen
rename (year_orig hs6_orig) (year hs6)
save $path/out/cn6_byyear, replace


