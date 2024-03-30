/*

	1_FIRSTSTAGE_BANKLEVEL:
	
	This file shows bank-level outcomes by treatment (wholesale-funded banks)

	DEPENDENCIES:
	
	Inputs:
	- data/2_bank_data/out/banks_panel.dta
	   treatment loans_ft loans_uv_s0 year bnk_cvrnr endyear

	Outputs:
	 - Fig 1a-b

*/


global path = "$projectpath/analysis/2_firststage"
cd $path
cap mkdir $path/out
global folder = "$path/out"


use $projectpath/data/2_bank_data/out/banks_panel, clear
keep treatment loans_ft loans_uv_s0 year bnk_cvrnr endyear

********************************************************************************
* Aggregate diff in diff loans
********************************************************************************

preserve
gcollapse (sum) loans_ft loans_uv_s0, by(year treatment)
keep if year>=2005 & year<=2010

gegen loans_ft07 = max(loans_ft*(year==2007)), by(treatment)
replace loans_ft = loans_ft/loans_ft07

gegen loans_uv_s007 = max(loans_uv_s0*(year==2007)), by(treatment)
replace loans_uv_s0 = loans_uv_s0/loans_uv_s007


twoway (connected loans_uv_s0 year if treatment==0, color(black) msize(large) mfcolor(white)) ///
	(connected loans_ft year if treatment==0, color(gs10) msize(large) mfcolor(white) lpattern(dash)) ///
	(connected loans_uv_s0 year if treatment==1, color(red) msize(large) lpattern(solid)) ///
	(connected loans_ft year if treatment==1, color(red%30) msize(large) lpattern(dash)) ///
	(connected loans_uv_s0 year if treatment==1, color(red) msize(large) lpattern(solid)) ///
	, xlabel(2005(1)2010) legend(order(1 "Deposit-funded, loans to firms" 2 "Deposit-funded, all loans" 3 "Wholesale-funded, loans to firms"  4 "Wholesale-funded, all loans") cols(2)) ytitle("Log loans relative to 2007") xtitle("") ylabel(0.5(0.1)1.2)
graph export $folder/Fig1a_aggregate_did.pdf, as(pdf) replace
restore

********************************************************************************
* Bank deaths 2007 market share
********************************************************************************
preserve
gegen loans_uv_s0_total = total(loans_uv_s0), by(year)

gen ms_firms = loans_uv_s0 / loans_uv_s0_total
gegen ms_firms07 = max((year==2007) * ms_firms), by(bnk_cvrnr)

egen loans_ft_total = total(loans_ft), by(year)
gen ms_allloans = loans_ft / loans_ft_total
gegen ms_allloans07 = max((year==2007)*ms_allloans), by(bnk_cvrnr)

egen endyear07 = max((year==2007)*endyear), by(bnk_cvrnr)
gen dead = year>=endyear07

gen deadmsfirms07 = ms_firms07 * dead
gen deadmsall07 = ms_allloans07 * dead

gcollapse (sum) deadmsfirms07 deadmsall07, by(year treatment)
keep if inrange(year, 2007,2010)
twoway (connected deadmsall07 year if treatment==0, color(gs10) msize(large) mfcolor(white) lpattern(dash)) ///
	(connected deadmsfirms07 year if treatment==0, color(black) msize(large) mfcolor(white)) ///
	(connected deadmsfirms07 year if treatment==1, color(red) msize(large) lpattern(solid)) ///
	(connected deadmsall07 year if treatment==1, color(red%30) msize(large) lpattern(dash)),  ///
	legend(order(2 "Deposit-funded, loans to firms" 1 "Deposit-funded, all loans" 3 "Wholesale-funded, loans to firms"  4 "Wholesale-funded, all loans") cols(2)) ytitle("2007 market share of resolved banks") xtitle("")
graph export $folder/Fig1b_bank_deaths.pdf, as(pdf) replace
restore

