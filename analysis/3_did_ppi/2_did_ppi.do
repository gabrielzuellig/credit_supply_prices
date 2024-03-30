/*

	2_DID_PPI:
	
	Estimation of dynamic difference-in-difference regressions with PPI data (Section IV)

	DEPENDENCIES:
	
	Inputs:
	 - analysis/3_did_ppi/temp/panel (good-quarter-level), ready for diff-in-diff estimations,
	   see 1_gen_panel for variable list

	Outputs:
	 - Fig 3a
	 - Tab A.6-A.7

*/

global path = "$projectpath/analysis/3_did_ppi"
cd $path
cap mkdir $path/out
cap mkdir $folder

global folder = "$path/out"

********************************************************************************
* prep and settings
********************************************************************************

use $path/temp/panel, clear

global sample = "has_2007 & has_2008 & has_2009 & has_2010 & loans_uv07>=100 & loans_uv06>=100 & loans_to_revenue07>=0.01 & nationtype==2"
global controls = "ib95.th##c.loans_to_revenue07 ib95.th##c.deposits_to_revenue07 ib95.th##c.stshare07 ib95.th##c.interest_rate07"
global fe = "panid ib95.th#nace"
global period = "year>=2005 & year<=2010"

winsor2 interest_rate07 loans_to_revenue07 deposits_to_revenue07, cut(1 99) replace


********************************************************************************
* (1) Baseline graph
********************************************************************************

reghdfe lprisadj2 ib95.th##c.tt_uvall $controls if $period & $sample, absorb($fe) cl(cvrnr)
est sto exposure_all
coefplot ///
	(exposure_all, offset(-0.05) label("Overall exposure") keep(*th#c.tt_uvall)) ///
	, $coefplot_settings  rename($rename_list) ytitle("Price relative to 2007H2") ylabel(-0.05(0.025)0.1)
graph export $folder/Fig3a_ppi_baseline.pdf, as(pdf) replace


********************************************************************************
* (2) Tables
********************************************************************************

global fe = "panid year#nace"
global allcontrols = "i.year##(c.stshare07 c.loans_to_revenue07 c.deposits_to_revenue07 c.interest_rate07 c.emp07 c.lemp07 c.revenue07 c.lrevenue07 c.equity_share07 c.profit_to_revenue07 c.ms_4d07 c.avg_wage07 c.firmage04 c.profit_to_revenue07 c.connections_loans07 c.connections_deposits07 c.inv_to_revenue07 c.equity_share07 c.pbshare07)"
global pdslassox = "stshare07 loans_to_revenue07 deposits_to_revenue07 interest_rate07 emp07 lemp07 revenue07 lrevenue07 equity_share07 profit_to_revenue07 ms_4d07 avg_wage07 firmage04 profit_to_revenue07 connections_loans07 connections_deposits07 inv_to_revenue07 equity_share07 pbshare07"

**  specifications table
* baseline
reghdfe lprisadj2 ib2007.year##c.tt_uvall $controls if $period & $sample, absorb($fe) cl(cvrnr)
eststo_wrap, model("baseline_ppi")
* firm-specific linear time trend
reghdfe lprisadj2 ib2007.year##c.tt_uvall $controls if $period & $sample, absorb(panid year#nace c.tq##cvrnr) cl(cvrnr)
eststo_wrap, model("trend")
* product-time fixed effect
reghdfe lprisadj2 ib2007.year##c.tt_uvall $controls if $period & $sample, absorb(panid year#nace year#cn2) cl(cvrnr)
eststo_wrap, model("cn")
* no control variables
reghdfe lprisadj2 ib2007.year##c.tt_uvall if $period & $sample, absorb($fe) cl(cvrnr)
eststo_wrap, model("noctrl")
* pdslasso
rlasso_fe if $sample & $period, y(lprisadj2) tt(tt_uvall) absorbtt(nace) absorbdid(panid year#nace) x($pdslassox)
eststo_wrap, model("lasso")
* all ctrl
reghdfe lprisadj2 ib2007.year##c.tt_uvall $allcontrols if $period & $sample, absorb($fe) cl(cvrnr)
eststo_wrap, model("allctrl")

* print table
loc models = "baseline_ppi trend cn noctrl lasso allctrl"
estfe `models', labels(panid "Firm-product" year#nace "time-4d NACE" year#cn2 "time-2d CN" cvrnr#c.tq "Firm trend")
loc ind = r(indicate_fe)
esttab `models', $esttab_rename_years keep(2008.year 2009.year 2010.year) $esttab_settings ///
mtitles("Baseline" "Trend" "CN" "No ctrl" "PDSLASSO") scalar(Firms tt_predictors y_predictors) indicate(`ind') b(3) se(3) sfmt(0) 

esttab `models' using $folder/TabA6_ppi_table_specifications.tex, $esttab_rename_years keep(2008.year 2009.year 2010.year) $esttab_settings ///
mtitles("Baseline" "Trend" "CN" "No ctrl" "PDSLASSO") scalar(Firms tt_predictors y_predictors) indicate(`ind') b(3) se(3) sfmt(0)  $esttab_tabularx replace

** samples table
* full/no exposure
reghdfe lprisadj2 ib2007.year##c.tt_uvall $controls if $period & $sample & (tt_uvall<0.02 | tt_uvall>0.98), absorb($fe) cl(cvrnr)
eststo_wrap, model("fullnoexp")
* high pb share
reghdfe lprisadj2 ib2007.year##c.tt_uvall $controls if $period & $sample & (pbshare07>0.98), absorb($fe) cl(cvrnr)
eststo_wrap, model("hipbshare")
* include product entry/exit, i.e. drop the has_* variables from sample restriction
reghdfe lprisadj2 ib2007.year##c.tt_uvall $controls if $period & nationtype==2 & loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01, absorb($fe) cl(cvrnr)
eststo_wrap, model("entryexit")
* drop the nationtype = 2 (domestic) from sample restriction
reghdfe lprisadj2 ib2007.year##c.tt_uvall $controls if $period & has_2007 & has_2008 & has_2009 & has_2010 & loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01, absorb($fe) cl(cvrnr)
eststo_wrap, model("exp")
* drop the loans_uv>100 etc. sample restrictions
reghdfe lprisadj2 ib2007.year##c.tt_uvall $controls if $period & has_2007 & has_2008 & has_2009 & has_2010 & nationtype==2, absorb($fe) cl(cvrnr)
eststo_wrap, model("loloans")
* drop all sample restrictions
reghdfe lprisadj2 ib2007.year##c.tt_uvall $controls if $period, absorb($fe) cl(cvrnr)
eststo_wrap, model("all")

* print table
loc models = "fullnoexp hipbshare entryexit exp loloans all"
estfe `models', labels(panid "Firm-product" year#nace "time-4d NACE" year#cn2 "time-2d CN" cvrnr#c.tq "Firm trend")
loc ind = r(indicate_fe)
esttab `models', $esttab_rename_years keep(2008.year 2009.year 2010.year) $esttab_settings ///
mtitles("Full/No Exposure" "Only 1 bank" "Incl. entry/exit" "Incl. Exports" "Incl. low loans" "No restr") scalar(Firms) indicate(`ind') b(3) se(3) sfmt(0) 

esttab `models' using $folder/TabA7_ppi_table_samples.tex, $esttab_rename_years keep(2008.year 2009.year 2010.year) $esttab_settings ///
mtitles("Full/No Exposure" "Only 1 bank" "Incl. entry/exit" "Incl. Exports" "Incl. low loans" "No restr") scalar(Firms) indicate(`ind') b(3) se(3) sfmt(0)  $esttab_tabularx replace
