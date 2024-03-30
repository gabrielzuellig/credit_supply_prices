/*

	4_DE_distributions:
	
	This file plots the distribution of Broda-Weinstein demand elasticities in different samples 
	
	DEPENDENCIES:
	
	Inputs:
	
	 - data/3_sample/temp/panel
	 
	 - data/5_demand_elasticities/out/firmlvl_DE_allcvrnr
	   
	 - data/5_demand_elasticities/temp/cdf_prodcom.dta
	 
	Outputs:
	 
	 - Fig 4c

*/

global path = "$projectpath/data/5_demand_elasticities"
cd $path
cap mkdir $path/out


******************************************************************************
// empirical CDF of sigmaBW in our sample 
******************************************************************************

* load firm panel to get relevant firms
use $projectpath/data/3_sample/temp/panel, replace
global sample = "loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01" 
keep if $sample & year == 2007
keep cvrnr revenue_fiks07
* merge firm-level demand-elasticities
merge 1:1 cvrnr using $path/out/firmlvl_DE_allcvrnr, keep(match master)
cumul sigmaBW_firmlvl [aw=revenue_fiks07], gen(cdf_ppiuhdm)
* save empirical cumulative distribution
collapse (max) cdf_ppiuhdm, by(sigmaBW_firmlvl)
sort cdf_ppiuhdm
rename sigmaBW_firmlvl sigmaBW
save $path/temp/cdf_firmdata, replace 


******************************************************************************
// plot figure: sigmaBW in firm data vs. PRODCOM
******************************************************************************

use $path/temp/cdf_prodcom.dta, replace 
append using $path/temp/cdf_firmdata
qui replace cdf_ppiuhdm = 0 if sigmaBW == 1
sort sigmaBW
foreach var of varlist cdf*{
	qui replace `var' = `var'[_n-1] if `var' == .
	gen temp = `var' < `var'[_n-1]
	list `var' if temp 
	drop temp
}
graph twoway (line cdf_ppiuhdm sigmaBW if sigmaBW <= 18, connect(J)) ///
	(line cdf_EU sigmaBW if sigmaBW <= 18, lcolor(maroon) lp(longdash) connect(J)) ///
	(line cdf_DK sigmaBW if sigmaBW <= 18, lcolor(maroon) lp(dash) connect(J)) ///
	(line cdf_DK_cpg sigmaBW if sigmaBW <= 18, lcolor(dkorange) lpattern(dash_dot) connect(J)) ///
	(line cdf_DK_food sigmaBW if sigmaBW <= 18, lcolor(dkorange) lpattern(shortdash) connect(J)), ///
	yline(0, lcolor(gs10)) yline(1, lcolor(gs10)) ///
	xsc(r(1 17)) xlab(1(1)17) xtitle("Demand elasticity") ytitle("Sales-weighted cumulative density") ///
	legend(pos(5) ring(0) r(5) order(1 "Firms in our samples" 2 "PRODCOM EU" 3 "PRODCOM Denmark" 4 " (Non-durable consumer goods)" 5 " (Food and beverage manufacturing)")) xsize(8) ysize(4)
graph export $path/out/Fig4c_prodcom_cdf.pdf, as(pdf) replace	
	
	
	
	
	
	