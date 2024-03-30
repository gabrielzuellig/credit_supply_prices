/*

	1_gen_bank_panel:
	
	This file creates a panel of bank-level variables based on URTEVIRK totals and MFI / FT balance sheet data,

	DEPENDENCIES:
	
	Inputs:
	
	- "$projectpath/data/1_combine_irtevirk_urtevirk/out/firm_bank_panel"
	  exhaustive varlist: cvrnr year bnk_cvrnr loans_uv
	
	- $cleandatapath/FIRM/out/firm_nyvar_`year'
	  exhaustive varlist: JUR_VIRK_FORM GF_NACE_DB07
	
	- $projectpath/data/00_mfi_data_DO_NOT_EXPORT/out/mfi_data_2007
	  exhaustive varlist: 2007 values of all FT and MFI variables
	
	Outputs:
	 - $path/out/banks_panel
		
*/

global path = "$projectpath/data/2_bank_data"
cd $path
cap mkdir out
cap mkdir temp

* generate bank-level UV variables
use "$projectpath/data/1_combine_irtevirk_urtevirk/out/firm_bank_panel", clear
keep if year<=2016 & year>=2003

* merge firm register
forval year = 2003 / 2016 {
	merge m:1 cvrnr year using $cleandatapath/FIRM/out/firm_nyvar_`year', keepusing(GF_NACE_DB07 JUR_VIRK_FORM) update keep(match master match_update) nogen
}

cap drop nace2d
gen nace2d = real(substr(GF_NACE_DB07),1, 2)

gen sample0 = 1 /* ALL LOANS */
gen sample2 = !inrange(nace2d, 64, 66) & inlist(JUR_VIRK_FORM, 80, 60, 10, 90, 81, 280, 100, 130, 210, 150, 140, 40, 170, 180, 30, 285, 270, 15, 20, 70, 290, 190, 160) /* NFC LOANS */

gen loans_uv_s0 = loans_uv * sample0
gen loans_uv_s2 = loans_uv * sample2

gcollapse (sum) loans_uv_s0 loans_uv_s2, by(year bnk_cvrnr) fast

save $path/temp/urtevirk_totals, replace

use $projectpath/data/00_mfi_data_DO_NOT_EXPORT/out/mfi_data_2007, clear
expand 10
bys bnk_cvrnr: gen year = _n+2002

merge 1:1 bnk_cvrnr year using $path/temp/urtevirk_totals, nogen
merge 1:1 bnk_cvrnr year using $projectpath/data/00_mfi_data_DO_NOT_EXPORT/out/mfi_panel, nogen

keep if inrange(year, 2003, 2012)

foreach var of varlist loans* deposits* {
	replace `var' = 0 if `var' == .
}

save $path/out/banks_panel, replace