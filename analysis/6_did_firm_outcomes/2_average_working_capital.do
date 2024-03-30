/*

	2_average_working_capital:
	
	This file collects data for the back-of-the-envelope financing cost pass-through
	estimation in Table 5 (Section V)

	DEPENDENCIES:
	
	Inputs:
	
	 - data/3_sample/out/panel.dta
	 
	Outputs:
	 - Tab 5

*/


global path = "$projectpath/analysis\6_did_firm_outcomes"
cd $path
cap mkdir out
global folder = "$path/out"

********************************************************************************
* settings
********************************************************************************

// settings
global period = "year>2004 & year<2011"
global period2 = "year>2004 & year<2015"
global sample = "loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01"
global survival = "has2005 & has_2006 & has_2007 & has_2008 & has_2009 & has_2010"
global controls = "ib2007.year##c.stshare07 ib2007.year##c.loans_to_revenue07 ib2007.year##c.deposits_to_revenue07 ib2007.year##c.interest_rate07"


********************************************************************************
* data prep
********************************************************************************

use $projectpath/data/3_sample/out/panel.dta, replace

// baseline interest rate in 2007: needed for back-of-the-envelope calculation
sum interest_rate07 if $period & $sample & year == 2007, det
global r_w = (1+r(mean))^(1/4)-1
disp "$r_w"

// r_w conditional on shock
replace interest_rate = interest_rate * 100
winsor2 interest_rate if $sample & $period, cut(2.5 97.5) suff(_wns) by(year)

reghdfe interest_rate_wns ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr nace#year) cl(cvrnr) 
global r_w_post = (1+_b[2010bn.year#c.tt_uvall]/100)^(1/4)-1
disp "$r_w_post"

// psi, working capital shares
// get relevant samples first
cap gen lrevenue_fiks = log(revenue_fiks)
reghdfe lrevenue_fiks ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
keep if e(sample) & year == 2007
// descriptive statistics for working capital back-of-the-envelope 
winsor2 wk_to_revenue07, cuts(0.5 99.5) replace  
sum wk_to_revenue07, det
global psi_avg = r(mean)*4
global psi_p10 = r(p10)*4
global psi_p90 = r(p90)*4
global psi_cet = 0.56

// Calculations for Table 5
log using $path/out/Tab5_margcosttable.log, replace

disp "Row 1: Christiano"
disp " - pre-finance share: " $psi_cet 
disp " - lending rate increase: " round($r_w_post *100, .01)
disp " - marginal cost increase: " round( ( $psi_cet / (1 - $psi_cet + $psi_cet*(1+$r_w)) )*$r_w_post * 100, .01)

disp "Row 2: Own data, mean"
disp " - pre-finance share: " round($psi_avg, .01)
disp " - lending rate increase: " round($r_w_post *100, .01)
disp " - marginal cost increase: " round( ( $psi_avg / (1 - $psi_avg + $psi_avg*(1+$r_w)) )*$r_w_post * 100, .01)

disp "Row 3: Own data, 10th percentile"
disp " - pre-finance share: " round($psi_p10, .01)
disp " - lending rate increase: " round($r_w_post *100, .01)
disp " - marginal cost increase: " round( ( $psi_p10 / (1 - $psi_p10 + $psi_p10*(1+$r_w)) )*$r_w_post * 100, .01)

disp "Row 4: Own data, 90th percentile"
disp " - pre-finance share: " round($psi_p90, .01)
disp " - lending rate increase: " round($r_w_post *100, .01)
disp " - marginal cost increase: " round( ( $psi_p90 / (1 - $psi_p90 + $psi_p90*(1+$r_w)) )*$r_w_post * 100, .01)

log close
 