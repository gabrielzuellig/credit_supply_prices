/*

	1_GEN_PPI_PANEL:
	
	This file perpares good-level PPI data used for the IV estimation

	DEPENDENCIES:
	
	Inputs:
	- $cleandatapath/PPI/out/quarterly/ppi_domestic.dta
	   tq year cvrnr prisadj2 hs6 panid nationtype

	- $cleandatapath/PPI/out/quarterly/ppi_exports.dta
	   tq year cvrnr prisadj2 hs6 panid nationtype
	   

	- $projectpath/data/3_sample/out/sample.dta
	   see analysis/4_did_ppi/1_gen_panel for variable list
	   
	- $projectpath/data/3_sample/out/panel.dta   
	   merged but not needed

	Outputs:
	 - analysis/5_iv/temp/panel (good category-year-level), ready to merge with unit values
	   in 2_iv_baseline

*/


global path = "$projectpath/analysis/5_iv"
cd $path
cap mkdir $path/out
cap mkdir $path/temp

********************************************************************************
* 1. start with ppi data
********************************************************************************

use $cleandatapath/PPI/out/quarterly/ppi_domestic, clear
append using $cleandatapath/PPI/out/quarterly/ppi_exports


********************************************************************************
* 2. merge sample
********************************************************************************

merge m:1 cvrnr using $projectpath/data/3_sample/out/sample, keep(match) nogen
merge m:1 cvrnr year using $projectpath/data/3_sample/out/panel, keep(match master) nogen
keep if inPPI // eliminates all firms that are not around in 2007 => 480 cvrnr's
drop if !inrange(year, 2003, 2015)

cap drop lloans_uv 
gen lloans_uv = log(loans_uv)
cap drop l1loans_uv 
gen l1loans_uv = log(loans_uv+(1+loans_uv^2)^(1/2))

********************************************************************************
* 3. misc
********************************************************************************
destring cvrnr, replace
replace hs = substr(hs,1,6)
gen cn4 = substr(hs, 1, 4)
gen cn2 = substr(hs, 1, 2)
destring cn4 cn2, replace
xtset panid tq
save $path/temp/panel, replace