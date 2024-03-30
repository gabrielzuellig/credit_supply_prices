/*

	1_GEN_EXPOSURE:
	
	This file generates the loan supply shock exposure from firms' 2007 bank links.

	DEPENDENCIES:
	
	Inputs:
	
	- $projectpath/data/1_combine_irtevirk_urtevirk/out/firm_bank_panel.dta
	  exhaustive varlist: cvrnr year bnk_cvrnr loans_uv
	
	- $projectpath/data/00_mfi_data_DO_NOT_EXPORT/out/mfi_data_2007.dta
	  exhaustive varlist: treatment control FS_group bid
	
	- $projectpath/data/1_combine_irtevirk_urtevirk/out/firm_panel.dta
	  exhaustive varlist: loans_uv loans_pb loans_st connections connections_loans
	  connections_deposits deposits interest_deposits
	
	Outputs:
	 - exposure.dta, firm-level, used in 2_gen_sample_2007
		

*/


global path = "$projectpath/data/3_sample"
cd $path
cap mkdir out

********************************************************************************
* account-level data (firm-bank-panel): define exposure
********************************************************************************

use $projectpath/data/1_combine_irtevirk_urtevirk/out/firm_bank_panel, clear
keep cvrnr year bnk_cvrnr loans_uv

merge m:1 bnk_cvrnr using $projectpath/data/00_mfi_data_DO_NOT_EXPORT/out/mfi_data_2007, keep(match master) keepus(treatment control FS_group bid)

keep if year == 2007

* total loans (at firm level)
gegen total_uv = total(loans_uv*!mi(treatment)), by(cvrnr year)
* main treatment variable: share of loans with 'treatment' (wholesale-funded) banks = tt_uvall
preserve 
gen tt_uvall = loans_uv * (treatment==1) / total_uv
gcollapse (sum) tt_uvall, by(cvrnr)
save $path/temp/exp_tt_uvall, replace
restore


********************************************************************************
* merge exposure (tt_uvall) back on firm-panel from URTEVIRK
********************************************************************************

use $projectpath/data/1_combine_irtevirk_urtevirk/out/firm_panel, clear
keep if year == 2007
drop year

* auxiliary variables
foreach var of varlist _all {
	if "`var'" != "cvrnr" & "`var'" != "year" & "`var'" != "pb_bid" & "`var'" != "pb_cvrnr" {
		rename `var' `var'07
	}
}

merge 1:1 cvrnr using $path/temp/exp_tt_uvall, nogen

label variable tt_uvall "Exposure"

compress
save $path/out/exposure, replace
