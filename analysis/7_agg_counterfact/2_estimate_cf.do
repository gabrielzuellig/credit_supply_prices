global path = "$projectpath/analysis/7_agg_counterfact"
cd $path
cap mkdir $path/out
cap mkdir $folder

*******************************************************************************
*** 1. get PPI data and mark sample used in DiD regression
*******************************************************************************

use $cleandatapath/PPI/out/quarterly/ppi_domestic, clear
merge m:1 cvrnr using $projectpath/data/3_sample/out/sample, nogen keep(match master) keepus(nace2d tt_uvall loans_uv* loans_to_revenue07 deposits_to_revenue07 stshare07 interest_rate07 nace)
merge m:1 cvrnr year using $projectpath/data/3_sample/out/panel, nogen keep(match master) keepus(revenue_fiks revenue_dom_fiks)
cap drop has*
gegen has_2004 = max((year==2004)), by(panid)
gegen has_2005 = max((year==2005)), by(panid)
gegen has_2006 = max((year==2006)), by(panid)
gegen has_2007 = max((year==2007)), by(panid)
gegen has_2008 = max((year==2008)), by(panid)
gegen has_2009 = max((year==2009)), by(panid)
gegen has_2010 = max((year==2010)), by(panid)
gegen has_2011 = max((year==2011)), by(panid)
gegen has_2012 = max((year==2012)), by(panid)
keep if tq >= tq(1995,3) & year <= 2016 // before and after: no weights
gen th = yh(year,halfyear(dofq(tq)))


*******************************************************************************
*** 2. Estimate diff-in-diff like in baseline, but with extended sample and quarterly estimates
*******************************************************************************
cap gen lPi = log(prisadj2)
xtset panid tq 
global sample = "has_2007 & has_2008 & has_2009 & has_2010 & loans_uv07>100 & loans_uv06>100 & loans_to_revenue07>0.01 & nationtype == 2"
global controls = "ib95.th##c.loans_to_revenue07 ib95.th##c.deposits_to_revenue07 ib95.th##c.stshare07 ib95.th##c.interest_rate07"
global fe = "panid ib95.th#nace"
global period = "year>=2005 & year<=2013"
	
reghdfe lPi ib95.th##c.tt_uvall $controls if $period & $sample, absorb($fe) cl(cvrnr)
est sto exposure_all
coefplot (exposure_all, offset(-0.05) label("Overall exposure") keep(*th#c.tt_uvall)), ///
	$coefplot_settings  rename($rename_list) ytitle("Price relative to 2007H2") ylabel(-0.05(0.025)0.1)

	
*******************************************************************************
*** 3. Build counterfactual
*******************************************************************************

gen counterfact_grp = e(sample)
replace counterfact_grp = 2 if counterfact_grp == 1 & tt_uvall > 0 //for counterfact_grp == 2, calculate counterfactual price 
tab counterfact_grp // 0: not in sample => control. 1: no exposure => control. 2: at least some exposure 

gen partial = 0
gen partial_1 = 0
gen partial_2 = 0
foreach i of numlist 96/107{  
	qui replace partial = _b[`i'.th#tt_uvall] if th == `i'
	qui replace partial_1 = _b[`i'.th#tt_uvall] + 1.645*_se[`i'.th#tt_uvall] if th == `i'
	qui replace partial_2 = _b[`i'.th#tt_uvall] - 1.645*_se[`i'.th#tt_uvall] if th == `i'
}

gen lPi_cfA = lPi 
replace lPi_cfA = lPi_cfA - partial if counterfact_grp == 2
gen lPi_cfA_1 = lPi
replace lPi_cfA_1 = lPi_cfA_1 - partial_1 if counterfact_grp == 2
gen lPi_cfA_2 = lPi
replace lPi_cfA_2 = lPi_cfA_2 - partial_2 if counterfact_grp == 2

*******************************************************************************
*** 4. Actual and counterfactual q/q 
*******************************************************************************

gen dP = Dp2
xtset panid tq
gen dP_cfA = lPi_cfA - L.lPi_cfA
gen dP_cfA_1 = lPi_cfA_1 - L.lPi_cfA_1
gen dP_cfA_2 = lPi_cfA_2 - L.lPi_cfA_2	

save $path/temp/panel_withcf, replace

