/*

	2_DID_UHDM:
	
	Estimation of dynamic difference-in-difference regressions with export unit value data (Section IV)

	DEPENDENCIES:
	
	Inputs:
	 - analysis/4_did_uhdm/temp/panel (good category-year-level), ready for diff-in-diff estimations,
	   see 1_gen_panel for variable list

	Outputs:
	 - Fig 3b
	 - Tab A.8-A.9

*/

global path = "$projectpath/analysis/4_did_uhdm"
cd $path
cap mkdir $path/out
global folder = "$path/out"


********************************************************************************
* prep and settings (incl. freghdfe and frlasse_fe functions)
********************************************************************************
use $path/temp/panel, clear

global sample_all = "loans_to_revenue07>0.01 & loans_uv07>100 & loans_uv06>100 & has_2005 & has_2006 & has_2007 & has_2008 & has_2009 & has_2010"
global controls = "ib2007.year##c.loans_to_revenue07 ib2007.year##c.deposits_to_revenue07 ib2007.year##c.stshare07 ib2007.year##c.interest_rate07"
global period = "year>=2005 & year<=2010"
gdistinct cvrnr if $sample_all & $period

cap program drop freghdfe
program def freghdfe
	syntax anything [if], [iterate(int 40) eps(real 0.001) wins(real 0.03)] *
	cap drop tempw
	gen tempw = 1
	local diffsd = 1
	local i = 1
	while `diffsd'>`eps' & `i'<`iterate'{
		cap drop resids
		qui reghdfe `anything' [aw = tempw] `if', `options' resid(resids)
		cap drop tempsd
		qui gegen tempsd = sd(resids) if e(sample), by(panid)
		qui replace tempsd = `wins' if tempsd<`wins'
		cap drop neww
		cap drop diff
		qui gen neww = 1/tempsd^2
		qui gen diff = abs(log(tempw/neww))
		sum diff if e(sample)
		local diffsd = r(sd)
		qui replace tempw = neww
		loc i = `i'+1
	}
	di "`i'"
	cap drop finalw
	qui gen finalw = tempw
	reghdfe `anything'  [aw = tempw] `if', `options'
	cap drop tempw
end

cap program drop frlasso_fe
program def frlasso_fe
	syntax anything [if], [iterate(int 5) wins(real 0.05)] *
	cap drop tempw
	gen tempw = 1
	forval i = 1/`iterate' {
		cap drop resids
		rlasso_fe `if', `options' weights(tempw) resid(resids)
		cap drop tempw
		cap drop tempsd
		qui gegen tempsd = sd(resids), by(panid)
		replace tempsd = 0.05 if tempsd<0.05
		qui gen tempw = 1/tempsd^2
	}
	rlasso_fe `if', `options' weights(tempw)
	cap drop tempw
end

xtset panid year
winsor2 loans_to_revenue07 deposits_to_revenue07 stshare07 interest_rate07, cut(2 98) replace

global allcontrols = "i.year##(c.stshare07 c.loans_to_revenue07 c.deposits_to_revenue07 c.interest_rate07 c.emp07 c.lemp07 c.revenue07 c.lrevenue07 c.equity_share07 c.profit_to_revenue07 c.ms_4d07 c.avg_wage07 c.firmage04 c.profit_to_revenue07 c.connections_loans07 c.connections_deposits07 c.inv_to_revenue07 c.equity_share07 c.pbshare07)"
global pdslassox = "stshare07 loans_to_revenue07 deposits_to_revenue07 interest_rate07 emp07 lemp07 revenue07 lrevenue07 equity_share07 profit_to_revenue07 ms_4d07 avg_wage07 firmage04 profit_to_revenue07 connections_loans07 connections_deposits07 inv_to_revenue07 equity_share07 pbshare07"


********************************************************************************
* (1) Baseline graph
********************************************************************************

freghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all, absorb(panid year#nace) cl(cvrnr)
eststo_wrap, model("baseline_uhdm")
cap gegen bslwgt = mean(finalw), by(panid)

coefplot  baseline_uhdm, keep(*.year#c.tt_uvall) ///
	rename($rename_list) $coefplot_settings ylabel(-0.05(0.025)0.1)
graph export $path/out/Fig3b_uhdm_baseline.pdf, as(pdf) replace


********************************************************************************
* (2) Tables
********************************************************************************

** specifications table
* firm-specific linear time trend
reghdfe luv1 c.year#i.firm_id if $period & $sample_all, absorb(i.panid)
predict firmtrend, xb
gen luv_detrend = luv1 - firmtrend
freghdfe luv_detrend ib2007.year##c.tt_uvall $controls if $period & $sample_all, absorb(i.panid i.year##i.nace) cl(cvrnr)
eststo_wrap, model("trend")
* product-time fixed effect
destring cn2, replace
freghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all, absorb(panid year#nace year#cn2) cl(cvrnr) iterate(25)
eststo_wrap, model("cn")
* no control variables
freghdfe luv1 ib2007.year##c.tt_uvall if $period & $sample_all, absorb(panid year#nace) cl(cvrnr) iterate(25)
eststo_wrap, model("noctrl")
// fixed rlasso; use weights of baseline estimation and do rlasso conditional on these weights
rlasso_fe if $sample_all & $period, y(luv1) tt(tt_uvall) absorbtt(nace) weights(bslwgt) absorbdid(panid year#nace) x($pdslassox)
eststo_wrap, model("lasso")
freghdfe luv1 ib2007.year##c.tt_uvall $allcontrols if $period & $sample_all, absorb(panid year#nace) cl(cvrnr) iterate(25)
eststo_wrap, model("allctrl")

* print table
loc models = "baseline_uhdm trend cn noctrl lasso allctrl"
estfe `models', labels($fe_indicators)
loc ind = r(indicate_fe)
esttab `models', keep(2008.year#c.tt_uvall 2009.year#c.tt_uvall 2010.year#c.tt_uvall) rename(2008.year0#c.tt_uvall 2008.year#c.tt_uvall 2009.year0#c.tt_uvall 2009.year#c.tt_uvall 2010.year0#c.tt_uvall 2010.year#c.tt_uvall) $esttab_settings ///
mtitles("Baseline" "Trend" "CN" "No ctrl" "PDSLASSO" "All controls") scalar(Firms tt_predictors y_predictors) indicate(`ind') b(3) se(3) sfmt(0) 

esttab `models' using $folder/TabA8_uhdm_table_specifications.tex, keep(2008.year#c.tt_uvall 2009.year#c.tt_uvall 2010.year#c.tt_uvall) rename(2008.year0#c.tt_uvall 2008.year#c.tt_uvall 2009.year0#c.tt_uvall 2009.year#c.tt_uvall 2010.year0#c.tt_uvall 2010.year#c.tt_uvall) $esttab_settings ///
mtitles("Baseline" "Trend" "CN" "No ctrl" "PDSLASSO" "All controls") scalar(Firms tt_predictors y_predictors) indicate(`ind') b(3) se(3) sfmt(0)  $esttab_tabularx replace

** samples table
* full/no exposure
freghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & (tt_uvall<0.02 | tt_uvall>0.98), absorb(panid year#nace) cl(cvrnr)
eststo_wrap, model("fullnoexp")
* high pb share
freghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & (pbshare07>0.98), absorb(panid year#nace) cl(cvrnr)
eststo_wrap, model("hipbshare")
* include product entry/exit, i.e. drop the has_* variables from sample restriction
freghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & has_2005 & has_2006 & has_2007 & loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01, absorb(panid year#nace) cl(cvrnr)
eststo_wrap, model("entryexit")
* drop the loans_uv>100 etc. sample restrictions
freghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & loans_uv06>100 & loans_uv07>100 & has_2005 & has_2006 & has_2007 & has_2008 & has_2009 & has_2010, absorb(panid year#nace) cl(cvrnr)
eststo_wrap, model("loloans")
* drop all sample restrictions
freghdfe luv1 ib2007.year##c.tt_uvall $controls if $period, absorb(panid year#nace) cl(cvrnr) iterate(25)
eststo_wrap, model("norestr")

* print table
loc models = "fullnoexp hipbshare entryexit loloans norestr"
estfe `models', labels(panid "Firm-product" year#nace "time-4d NACE" year#CN2 "time-2d CN" cvrnr#c.year "Firm trend")
loc ind = r(indicate_fe)
esttab `models', keep(2008.year#c.tt_uvall 2009.year#c.tt_uvall 2010.year#c.tt_uvall) $esttab_settings ///
mtitles("Full/No Exposure" "Only 1 bank" "Incl. exit" "Incl. low loans" "No restrictions") scalar(Firms tt_predictors y_predictors) indicate(`ind') b(3) se(3) sfmt(0) 

esttab `models' using $folder/TabA9_uhdm_table_samples.tex, keep(2008.year#c.tt_uvall 2009.year#c.tt_uvall 2010.year#c.tt_uvall) $esttab_settings ///
mtitles("Full/No Exposure" "Only 1 bank" "Incl. entry/exit" "Incl. low loans" "No restrictions") scalar(Firms tt_predictors y_predictors) indicate(`ind') b(3) se(3) sfmt(0)  $esttab_tabularx replace


********************************************************************************
* (3) FGLS robustness: exclude most volatile series and estimate by OLS
********************************************************************************

reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all, absorb(panid year#nace) cl(cvrnr)
eststo_wrap, model("now")

coefplot now, keep(*.year#c.tt_uvall) ///
	rename($rename_list) $coefplot_settings ylabel(-0.05(0.025)0.1)

keep if inrange(year,2005,2010)
reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all, absorb(panid year#nace) cl(cvrnr) resid(residuals)
gegen sd_resids = sd(residuals), by(panid)

gegen series_sd = sd(luv1), by(panid)
gegen series_mean = mean(luv1), by(panid)

gen value07mio = value07 / 1000000
binscatter value07mio sd_resids if year==2007 & $sample_all, linetype(none) xtitle("SD of first-step resiual series 2005-2010") ytitle("2007 export value (in mio.)") ylabel(0(25)200)
binscatter value07mio series_sd if year==2007 & $sample_all, linetype(none) xtitle("SD of log unit value series 2005-2010") ytitle("2007 export value (in mio.)") ylabel(0(25)200)

_pctile sd_resids if $sample_all & year==2007, nq(9)
loc p1 = r(r1)
loc p2 = r(r2)
loc p3 = r(r3)
loc p4 = r(r4)
loc p5 = r(r5)
loc p6 = r(r6)
loc p7 = r(r7)
loc p8 = r(r8)
loc p9 = r(r9)

reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & sd_resids<`p1', absorb(panid year#nace) cl(cvrnr)
est sto p1
reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & sd_resids<`p2', absorb(panid year#nace) cl(cvrnr)
est sto p2
reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & sd_resids<`p3', absorb(panid year#nace) cl(cvrnr)
est sto p3
reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & sd_resids<`p4', absorb(panid year#nace) cl(cvrnr)
est sto p4
reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & sd_resids<`p5', absorb(panid year#nace) cl(cvrnr)
est sto p5
reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & sd_resids<`p6', absorb(panid year#nace) cl(cvrnr)
est sto p6
reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & sd_resids<`p7', absorb(panid year#nace) cl(cvrnr)
est sto p7
reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & sd_resids<`p8', absorb(panid year#nace) cl(cvrnr)
est sto p8
reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all & sd_resids<`p9', absorb(panid year#nace) cl(cvrnr)
est sto p9
reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all, absorb(panid year#nace) cl(cvrnr)
est sto All

coefplot (p2 \ p3 \ p4 \ p5 \ p6 \ p7 \ p8 \ p9 \ All, keep(2008.year#c.tt_uvall) label("2008") offset(0)) (p2 \ p3 \ p4 \ p5 \ p6 \ p7 \ p8 \ p9 \ All, keep(2009.year#c.tt_uvall) label("2009") offset(0.05)) (p2 \ p3 \ p4 \ p5 \ p6 \ p7 \ p8 \ p9 \ All, keep(2010.year#c.tt_uvall) label("2010") offset(0.1)), swapnames asequation $coefplot_settings_noalt legend(rows(1)) ylabel(-0.05(0.025)0.1) xlabel(1 "2nd" 2 "3rd" 3 "4th" 4 "5th" 5 "6th" 6 "7th" 7 "8th" 8 "9th" 9 "Full sample") xtitle("Include series up to xth decile 1st step residual SD") levels(90)
graph export $folder/FigA6a_uhdm_fgls_robustness_weights.pdf, as(pdf) replace


********************************************************************************
* (4) FGLS robustness: number of iterations
********************************************************************************

reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all, absorb(panid year#nace) cl(cvrnr)
est sto piter0
foreach it of numlist 1(1)5 10(10)40{
   freghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all, absorb(panid year#nace) cl(cvrnr) iterate(`it') 
	est sto piter`it'
}

coefplot (piter0 \ piter1 \ piter2 \ piter3 \ piter4 \ piter5 \ piter10 \ piter20 \ piter30 \ piter40, keep(2008.year#c.tt_uvall) label("2008") offset(0)) ///
	(piter0 \ piter1 \ piter2 \ piter3 \ piter4 \ piter5 \ piter10 \ piter20 \ piter30 \ piter40, keep(2009.year#c.tt_uvall) label("2009") offset(0.05)) ///
	(piter0 \ piter1 \ piter2 \ piter3 \ piter4 \ piter5 \ piter10 \ piter20 \ piter30 \ piter40, keep(2010.year#c.tt_uvall) label("2010") offset(0.1)), ///
	swapnames asequation $coefplot_settings_noalt legend(rows(1)) ylabel(-0.05(0.025)0.1) ///
	xlabel(1 "0" 2 "1" 3 "2" 4 "3" 5 "4" 6 "5" 7 "10" 8 "20" 9 "30" 10 "40") ///
	xtitle("Number of iterations") levels(90)
graph export $folder/FigA6b_uhdm_fgls_robustness_numiter.pdf, as(pdf) replace
