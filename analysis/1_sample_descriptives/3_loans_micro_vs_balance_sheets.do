/*

	3_LOANS_MICRO_VS_BALANCE_SHEET:
	
	This file generates a binned scatter plot for two variables of bank-level loans,
	one directly measured from bank balance sheets and one aggregated from the
	account-level data

	DEPENDENCIES:
	
	Inputs:
	- $projectpath/data/1_banks/out/banks_panel.dta
	
	Outputs:
	 - Fig A.2a-b

*/

global path = "$projectpath/analysis/1_sample_descriptives"
cd $path
cap mkdir $path/out
global folder = "$path/out"

********************************************************************************
* Bank level
********************************************************************************

use $projectpath/data/2_bank_data/out/banks_panel, clear

*** Lending graphs for benchmarks ("verification of loan data")
* aggregate
preserve
drop if loans_ft==. | loans_ft==0 | loans_uv_s2 == . | loans_uv_s2 == 0
gdistinct bid if year==2007
gcollapse (sum) loans_ft loans_nfc loans_uv_s2, by(year)
replace loans_ft = loans_ft / 1000000
replace loans_nfc = loans_nfc / 1000000
replace loans_uv_s2 = loans_uv_s2 / 1000000
graph twoway (connected loans_nfc year, yaxis(1) ytitle("Bio. DKK", axis(1)) color(navy) msymbol(T)) ///
	(connected loans_uv_s2 year, yaxis(1) ytitle("Bio. DKK", axis(1)) color(green) msymbol(O) ) ///
	(line loans_ft year, yaxis(2) ytitle("Bio. DKK", axis(2)) color(maroon%70) lpattern(dash)) , ///
	legend(order(1 "NFC loans from balance sheets (left axis)" 2 "NFC loans in microdata (left axis)" 3 "Total loans from balance sheets (right axis)" ) cols(1)) xlabel(2003(1)2012) xtitle("")
graph export $folder/FigA2a_aggregate_absolute.pdf, as(pdf) replace
restore

* micro level binscatter
gen lloans_uv_s2 = log(loans_uv_s2)
gen lloans_nfc = log(loans_nfc)
binscatter lloans_uv_s2 lloans_nfc if !mi(ltd) & inrange(year,2005,2010), xtitle("Log NFC loans (Balance sheets)")  ytitle("Log NFC loans (Microdata)") linetype(none)
addplot: line lloans_nfc lloans_nfc if lloans_nfc>5
graph export $folder/FigA2b_bank_lvl_correlation.pdf, as(pdf) replace
