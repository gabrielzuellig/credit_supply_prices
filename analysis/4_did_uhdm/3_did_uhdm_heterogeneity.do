/*

	3_DID_UHDM_HETEROGENEITY:
	
	Estimation of dynamic difference-in-difference regressions with unit values data (Section IV),
	results on heterogeneous treatment effects

	DEPENDENCIES:
	
	Inputs:
	 - analysis/4_did_uhdm/temp/panel (good category-year-level), ready for diff-in-diff estimations,
	   see 1_gen_panel for variable list

	Outputs:
	 - Fig 4b
	 - Tab 3-4 (columns 4-6)

*/

global path = "$projectpath/analysis/4_did_uhdm"
cd $path
cap mkdir $path/out
global folder = "$path/out"


********************************************************************************
* prep and settings
********************************************************************************
use $path/temp/panel, clear

global sample = "loans_to_revenue07>0.01 & loans_uv07>100 & loans_uv06>100 & has_2005 & has_2006 & has_2007 & has_2008 & has_2009 & has_2010"
global controls = "ib2007.year##c.loans_to_revenue07 ib2007.year##c.deposits_to_revenue07 ib2007.year##c.stshare07 ib2007.year##c.interest_rate07"
global period = "year>=2005 & year<=2010"
keep if $period


********************************************************************************
* BASELINE / AVERAGE EFFECT
********************************************************************************

freghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample, absorb(panid year#nace) cl(cvrnr)
disp e(N_clust)
eststo_wrap, model("baseline_uhdm")
gen baselinesmpl = e(sample) 
count if baselinesmpl

global baseline_beta09 = _b[2009bn.year#c.tt_uvall]
gen yline_beta09 = $baseline_beta09
global baseline_se09 = _se[2009bn.year#c.tt_uvall]

bys cvrnr year baselinesmpl: gen uniquefirmyear = _n==1
qui replace uniquefirmyear = 0 if baselinesmpl == 0 

********************************************************************************
* Demand elasticity
********************************************************************************

* winsorize at (0 98)
winsor2 sigmaBW, cut(0 98) replace

* 'raw' measures to get regression sample
destring cn2, replace
reghdfe luv1 ib2007.year##c.tt_uvall##c.sigmaBW $controls if $period & $sample & baselinesmpl, absorb(panid cn2#year) cl(cvrnr)

* standardize demand elasticity and strategic complementarity
sum sigmaBW if e(sample) & year == 2007, det
global mom_sigma_mean = r(p50) // 2.38
global mom_sigma_sd = r(sd)    //2.57
gen sigmaBW_std = (sigmaBW - $mom_sigma_mean)/$mom_sigma_sd if e(sample)

* actual regression
freghdfe luv1 ib2007.year##c.tt_uvall##c.sigmaBW_std $controls if $period & $sample, absorb(panid cn2#year) cl(cvrnr)
eststo hetmodel_sigma_uhdm
gen usesmpl = e(sample)
qui distinct cvrnr if usesmpl
estadd scalar Firms = r(ndistinct)
sum sigmaBW if usesmpl, det
estadd scalar hetmean = $mom_sigma_mean
estadd scalar hetsd = $mom_sigma_sd

* figure: prepare necessary ingredients
cap drop idx me09
gen idx = _n if _n <= 10
global beta_const = _b[2009bn.year#tt_uvall]
global beta_slope = _b[2009bn.year#tt_uvall#sigmaBW_std]
gen me09 = $beta_const + $beta_slope * ((idx-$mom_sigma_mean)/$mom_sigma_sd)
cap drop kd*
kdensity sigmaBW if !inrange(cn2, 2, 24) & usesmpl == 1, bw(0.25) g(kd_sigma kd_dens)
sum sigmaBW if usesmpl == 1 & inrange(nace2d, 10, 11), det
global food_median = 8.6
global pcg_median = 5.7
gen food_median = $food_median
gen pcg_median = $pcg_median
cap drop zero me_up me_lo
gen zero = 0
gen me_up = me09 + 1.645*$baseline_se09
gen me_lo = me09 - 1.645*$baseline_se09

* figure: actual production
graph twoway (rcap me_lo me_up idx if idx <= 10.1) ///
	(scatter zero pcg_median, yaxis(2) recast(line) lcolor(dkorange) lpattern(dash)) ///
	(scatter zero food_median, yaxis(2) recast(line) lcolor(dkorange) lpattern(shortdash)) ///
	(connected me09 idx if idx <= 10.1, color(navy) lp(solid) msymbol(o)) ///
	(connected yline_beta09 idx if idx <= 10.1, color(maroon) msymbol(i)) ///
	(line kd_dens kd_sigma if kd_sigma <= 10.1, lcolor(gray) lp(solid) yaxis(2)), /// 
	title("") xtitle("Demand elasticity") ytitle("Price in 2009 relative to 2007") ///
	xsc(r(1 10)) xlab(1(1)10) ///
	ysc(r(-.1 .08) axis(1)) ylab(-.1(.04).08) yline(0, lcolor(black) lwidth(thin)) ///
	ysc(r(0 .9) axis(2)) ytitle("Kernel density", axis(2)) /// 
	xline($pcg_median, lcolor(dkorange) lpattern(dash)) ///
	xline($food_median, lcolor(dkorange) lpattern(shortdash)) ///
	legend(c(2) order(2 "Heterogeneous effect" 3 "Linear effect" 4 "Non-dur. cons. goods, median" 5 "Food a. bevg., median" 6 "Density in sample (right axis)"))
	graph export $path/out/Fig4b_uhdm_sigma_2009.pdf, as(pdf) replace

_pctile sigmaBW if usesmpl, p(90)


********************************************************************************
* Robustness: HS-version of demand elasticity
********************************************************************************

gen sigmaBWHS = sigmaBWHS_UHDM
winsor2 sigmaBWHS, cut(0 99) replace

* 'raw' measures to get regression sample
destring cn2, replace
reghdfe luv1 ib2007.year##c.tt_uvall##c.sigmaBWHS $controls if $period & $sample & baselinesmpl, absorb(panid cn2#year) cl(cvrnr)

* standardize demand elasticity and strategic complementarity
cap drop sigmaBWHS_std
sum sigmaBWHS if e(sample) & year == 2007, det
global mom_sigma_mean = r(p50) // 3.9
global mom_sigma_sd = r(sd)    // 8.6
gen sigmaBWHS_std = (sigmaBWHS - $mom_sigma_mean)/$mom_sigma_sd if e(sample)

* actual regression
freghdfe luv1 ib2007.year##c.tt_uvall##c.sigmaBWHS_std $controls if $period & $sample, absorb(panid cn2#year) cl(cvrnr)
eststo hetmodel_sigmahs_uhdm
cap drop usesmpl
gen usesmpl = e(sample)
qui distinct cvrnr if usesmpl
estadd scalar Firms = r(ndistinct)
sum sigmaBW if usesmpl, det
estadd scalar hetmean = $mom_sigma_mean
estadd scalar hetsd = $mom_sigma_sd


********************************************************************************
* Strategic complementarity
********************************************************************************

* 'raw' measures to get regression sample
cap destring cn2, replace
reghdfe luv1 ib2007.year##c.tt_uvall##c.betaSC_w $controls if $period & $sample & baselinesmpl, absorb(panid cn2#year) cl(cvrnr)

* standardize
sum betaSC_w if e(sample) & year == 2007, det
global mom_strcmp_mean = 0
global mom_strcmp_sd = r(sd)  // 0.16
cap drop betaSC_std
gen betaSC_std = (betaSC_w - $mom_strcmp_mean)/$mom_strcmp_sd if e(sample)

* actual regression
freghdfe luv1 ib2007.year##c.tt_uvall##c.betaSC_std $controls if $period & $sample, absorb(panid cn2#year) cl(cvrnr)
eststo hetmodel_strcmp_uhdm
cap drop usesmpl
gen usesmpl = e(sample)
qui distinct cvrnr if usesmpl
estadd scalar Firms = r(ndistinct)
estadd scalar hetmean = $mom_strcmp_mean
estadd scalar hetsd = $mom_strcmp_sd


********************************************************************************
* Print uhdm product-levelheterogeneity table
********************************************************************************

* product-level heterogeneities
esttab hetmodel_sigma_uhdm hetmodel_sigmahs_uhdm hetmodel_strcmp_uhdm, ///
	rename(2008.year#c.tt_uvall 2008 2009.year#c.tt_uvall 2009 2010.year#c.tt_uvall 2010  2008.year#c.tt_uvall#c.sigmaBW_std 2008interact 2009.year#c.tt_uvall#c.sigmaBW_std 2009interact 2010.year#c.tt_uvall#c.sigmaBW_std 2010interact 2008.year#c.tt_uvall#c.sigmaBWHS_std 2008interact 2009.year#c.tt_uvall#c.sigmaBWHS_std 2009interact 2010.year#c.tt_uvall#c.sigmaBWHS_std 2010interact 2008.year#c.tt_uvall#c.betaSC_std 2008interact 2009.year#c.tt_uvall#c.betaSC_std 2009interact 2010.year#c.tt_uvall#c.betaSC_std 2010interact) keep(2008 2009 2010 2008interact* 2009interact* 2010interact*) varlabels(2008interact "2008 x Interaction" 2009interact "2009 x Interaction" 2010interact "2010 x Interaction") mtitles("Demand elasticity" "Alternative" "Strat. comp." ) scalar(Firms hetmean hetsd) indicate("Firm-product = _cons") $esttab_settings b(3) se(3) sfmt(0 2) ti("Product-level heterogeneity")
	
esttab hetmodel_sigma_uhdm hetmodel_sigmahs_uhdm hetmodel_strcmp_uhdm using $path/out/Tab3_heterogeneity_productlevel_cols_4_6.tex, ///
	rename(2008.year#c.tt_uvall 2008 2009.year#c.tt_uvall 2009 2010.year#c.tt_uvall 2010  2008.year#c.tt_uvall#c.sigmaBW_std 2008interact 2009.year#c.tt_uvall#c.sigmaBW_std 2009interact 2010.year#c.tt_uvall#c.sigmaBW_std 2010interact 2008.year#c.tt_uvall#c.sigmaBWHS_std 2008interact 2009.year#c.tt_uvall#c.sigmaBWHS_std 2009interact 2010.year#c.tt_uvall#c.sigmaBWHS_std 2010interact 2008.year#c.tt_uvall#c.betaSC_std 2008interact 2009.year#c.tt_uvall#c.betaSC_std 2009interact 2010.year#c.tt_uvall#c.betaSC_std 2010interact) keep(2008 2009 2010 2008interact* 2009interact* 2010interact*) varlabels(2008interact "2008 x Interaction" 2009interact "2009 x Interaction" 2010interact "2010 x Interaction") mtitles("Demand elasticity" "Alternative" "Strat. comp.") scalar(Firms hetmean hetsd) indicate("Firm-product = _cons") $esttab_settings b(3) se(3) sfmt(0 2) ti("Product-level heterogeneity") replace
	

********************************************************************************
* Liquidity
********************************************************************************

* prepare
sum deposits_to_revenue07 if year == 2007 & $sample, det
winsor2 deposits_to_revenue07 if $sample, cuts(0 99) replace

* 'raw' measures to get regression sample
reghdfe luv1 ib2007.year##c.tt_uvall##c.deposits_to_revenue07 $controls if $period & $sample, absorb(panid year#nace) cl(cvrnr)

* standardize (at firm, not product level)
cap drop deposits_to_revenue07_std
sum deposits_to_revenue07 if e(sample) & year == 2007 & uniquefirmyear == 1
global mom_z_mean = r(mean)
global mom_z_sd = r(sd)
gen deposits_to_revenue07_std = (deposits_to_revenue07 - $mom_z_mean) /  $mom_z_sd

* actual regression
freghdfe luv1 ib2007.year##c.tt_uvall##c.deposits_to_revenue07_std $controls if $period & $sample, absorb(panid year#nace) cl(cvrnr)
eststo hetmodel_liquidity_uhdm
cap drop usesmpl
gen usesmpl = e(sample)
qui distinct cvrnr if usesmpl
estadd scalar Firms = r(ndistinct)
estadd scalar hetmean = $mom_z_mean
estadd scalar hetsd = $mom_z_sd

	
********************************************************************************
* Working capital
********************************************************************************

sum wk_to_revenue07 if year == 2007 & $sample, det
winsor2 wk_to_revenue07, cuts(0.5 99.5) replace 

* 'raw' measures to get regression sample
reghdfe luv1 ib2007.year##c.tt_uvall##c.wk_to_revenue07 $controls if $period & $sample, absorb(panid year#nace) cl(cvrnr)

* standardize (at firm, not product level)
cap drop wk_to_revenue07_std
sum wk_to_revenue07 if e(sample) & year == 2007 & uniquefirmyear == 1
global mom_z_mean = r(mean)
global mom_z_sd = r(sd)
gen wk_to_revenue07_std = (wk_to_revenue07 - $mom_z_mean) /  $mom_z_sd

* actual regression
freghdfe luv1 ib2007.year##c.tt_uvall##c.wk_to_revenue07_std $controls if $period & $sample, absorb(panid year#nace) cl(cvrnr)
eststo hetmodel_workcap_uhdm
cap drop usesmpl
gen usesmpl = e(sample)
qui distinct cvrnr if usesmpl
estadd scalar Firms = r(ndistinct)
estadd scalar hetmean = $mom_z_mean 
estadd scalar hetsd = $mom_z_sd

* firm-level heterogeneity table (appendix)
esttab hetmodel_liquidity_uhdm hetmodel_workcap_uhdm, ///
	rename(2008.year#c.tt_uvall 2008 2009.year#c.tt_uvall 2009 2010.year#c.tt_uvall 2010  2008.year#c.tt_uvall#c.deposits_to_revenue07_std 2008interact 2009.year#c.tt_uvall#c.deposits_to_revenue07_std 2009interact 2010.year#c.tt_uvall#c.deposits_to_revenue07_std 2010interact 2008.year#c.tt_uvall#c.wk_to_revenue07_std 2008interact 2009.year#c.tt_uvall#c.wk_to_revenue07_std 2009interact 2010.year#c.tt_uvall#c.wk_to_revenue07_std 2010interact) keep(2008 2009 2010 2008interact* 2009interact* 2010interact*) varlabels(2008interact "2008 x Interaction" 2009interact "2009 x Interaction" 2010interact "2010 x Interaction") mtitles("Liquidity" "Working capital") scalar(Firms hetmean hetsd) indicate("Firm-product = _cons") $esttab_settings b(3) se(3) sfmt(0 2) ti("Product-level heterogeneity")
	
esttab hetmodel_liquidity_uhdm hetmodel_workcap_uhdm using $path/out/Tab4_heterogeneity_firmlevel_cols_4_6.tex, ///
	rename(2008.year#c.tt_uvall 2008 2009.year#c.tt_uvall 2009 2010.year#c.tt_uvall 2010  2008.year#c.tt_uvall#c.deposits_to_revenue07_std 2008interact 2009.year#c.tt_uvall#c.deposits_to_revenue07_std 2009interact 2010.year#c.tt_uvall#c.deposits_to_revenue07_std 2010interact 2008.year#c.tt_uvall#c.wk_to_revenue07_std 2008interact 2009.year#c.tt_uvall#c.wk_to_revenue07_std 2009interact 2010.year#c.tt_uvall#c.wk_to_revenue07_std 2010interact) keep(2008 2009 2010 2008interact* 2009interact* 2010interact*) varlabels(2008interact "2008 x Interaction" 2009interact "2009 x Interaction" 2010interact "2010 x Interaction") mtitles("Liquidity" "Working capital") scalar(Firms hetmean hetsd) indicate("Firm-product = _cons") $esttab_settings b(3) se(3) sfmt(0 2) ti("Product-level heterogeneity") replace	
	