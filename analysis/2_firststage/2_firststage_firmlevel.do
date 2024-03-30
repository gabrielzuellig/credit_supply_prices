/*

	2_FIRSTSTAGE_FIRMLEVEL:
	
	This file estimates firm-level loan outcomes presented in Section III 
	(and referenced appendices)

	DEPENDENCIES:
	
	Inputs:
	 - data/3_sample/out/panel.dta, of which the following variables (exhaustive)
	   cvrnr year nace nace2d firm_id interest_rate loans_uv loans_uv06 loans_uv07 
	   loans_to_revenue07 jkod07 inPPI inUHDM tt_uvall stshare07 deposits_to_revenue07 
	   interest_rate07 emp07 lemp07  ms_4d07  avg_wage07  firmage04 connections_loans07  
	   connections_deposits07  inv_to_revenue07  equity_share07  pbshare07 revenue07 
	   lrevenue07  profit_to_revenue07 loans_pre07 loans_new loans_pb
	 
	Outputs:
	 - Fig 2a-2f 
	 - Tab A.3-A.5
		
*/


global path = "$projectpath/analysis/2_firststage"
cd $path
cap mkdir $path/out
global folder = "$path/out"


********************************************************************************
// Load data and prepare transformations
********************************************************************************

use $projectpath/data/3_sample/out/panel, replace
destring cvrnr, replace
xtset cvrnr year

keep if year>=2004 & year<=2010 // keep 1 lag for interest rate

// auxiliary variables
gen l1loans_uv = log(loans_uv + (loans_uv^2+1)^(1/2))
gen lloans_uv = log(loans_uv)
cap drop loans_uv07
gegen loans_uv07 = max(loans_uv*(year==2007)), by(cvrnr)
gen loans_uv_gr = loans_uv / loans_uv07 - 1
winsor2 interest_rate07 loans_to_revenue07 deposits_to_revenue07, cut(2 98) replace

label def years 2008 "2008" 2009 "2009" 2010 "2010", replace
label values year years


********************************************************************************
// Settings
********************************************************************************

global sample = `"loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01 & jkod07!="R""'
global period = "year>=2005 & year<=2010"
global controls = "ib2007.year##c.stshare07 ib2007.year##c.loans_to_revenue07 ib2007.year##c.deposits_to_revenue07 ib2007.year##c.interest_rate07"


******************************************************************************* 
// Main result on volumes
******************************************************************************* 

reghdfe l1loans_uv ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr nace#year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol_prices")
reghdfe l1loans_uv ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr nace#year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol")

coefplot (log1_vol_prices, offset(-0.1) label("Firms in price data")) ///
 (log1_vol, label("All manufacturing firms")), ///
 $coefplot_settings keep(*.year#c.tt_uvall) rename(*.year#c.tt_uvall=.year) ytitle("IHS of loans relative to 2007") levels(95)
graph export $folder/Fig2a_firststage_volumes.pdf, as(pdf) replace


******************************************************************************* 
// Volumes robustness tables
******************************************************************************* 

global allcontrols = "i.year##(c.stshare07 c.loans_to_revenue07 c.deposits_to_revenue07 c.interest_rate07 c.emp07 c.lemp07 c.revenue07 c.lrevenue07 c.equity_share07 c.profit_to_revenue07 c.ms_4d07 c.avg_wage07 c.firmage04 c.profit_to_revenue07 c.connections_loans07 c.connections_deposits07 c.inv_to_revenue07 c.equity_share07 c.pbshare07)"
global pdslassox = "stshare07 loans_to_revenue07 deposits_to_revenue07 interest_rate07 emp07 lemp07 revenue07 lrevenue07 equity_share07 profit_to_revenue07 ms_4d07 avg_wage07 firmage04 profit_to_revenue07 connections_loans07 connections_deposits07 inv_to_revenue07 equity_share07 pbshare07"

cap drop loans_uv_gr_wns
winsor2 loans_uv_gr if $period & $sample, cut(5 95) suff(_wns)

reghdfe l1loans_uv ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr nace#year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol")
reghdfe lloans_uv ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr nace#year) cl(cvrnr) nocons
eststo_wrap, model("log_vol")
rifhdreg loans_uv_gr ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr nace#year) cl(cvrnr) over(year)  rif(q(50)) nocons
eststo_wrap, model("rifreg_vol")

rifhdreg loans_uv_gr ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr nace#year) cl(cvrnr) over(year) rif(q(50)) nocons
eststo_wrap, model("rifreg_vol_prices")
reghdfe l1loans_uv ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr nace#year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol_prices")
reghdfe lloans_uv ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr nace#year) cl(cvrnr) nocons
eststo_wrap, model("log_vol_prices")

reghdfe l1loans_uv ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr nace2d#year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol_nace2")
reghdfe l1loans_uv (2008.year 2009.year 2010.year)##c.tt_uvall $controls if $period & $sample, abs(cvrnr nace#year firm_id##c.year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol_trend")
reghdfe l1loans_uv ib2007.year##c.tt_uvall if $period & $sample, abs(cvrnr nace#year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol_nctr")
rlasso_fe if $sample & $period, y(l1loans_uv) tt(tt_uvall) absorbtt(nace) absorbdid(cvrnr nace#year) x($pdslassox)
eststo_wrap, model("log1_vol_lasso")
reghdfe l1loans_uv ib2007.year##c.tt_uvall $allcontrols if $period & $sample, abs(cvrnr nace#year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol_allctrl")

reghdfe l1loans_uv ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr nace2d#year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol_nace2_prices")
reghdfe l1loans_uv (2008.year 2009.year 2010.year)##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(firm_id nace#year firm_id##c.year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol_trend_prices")
reghdfe l1loans_uv ib2007.year##c.tt_uvall if $period & $sample & (inPPI | inUHDM), abs(cvrnr nace#year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol_nctr_prices")
rlasso_fe if $sample & $period & (inPPI | inUHDM), y(l1loans_uv) tt(tt_uvall) absorbtt(nace) absorbdid(cvrnr nace#year) x($pdslassox)
eststo_wrap, model("log1_vol_lasso_prices")
reghdfe l1loans_uv ib2007.year##c.tt_uvall $allcontrols if $period & $sample &  (inPPI | inUHDM), abs(cvrnr nace#year) cl(cvrnr) nocons
eststo_wrap, model("log1_vol_allctrl_prices")

// Output tables

// Table A.3 Different transformations of loan volumes
loc models = "log1_vol_prices log_vol_prices rifreg_vol_prices log1_vol log_vol rifreg_vol "
estfe `models', labels(firm_id "Firm" nace#year "time-4d NACE")
loc ind = r(indicate_fe)
esttab `models', $esttab_rename_years keep(2008.year 2009.year 2010.year) $esttab_settings ///
mtitles("IHS" "Log" "GR RIFreg" "IHS" "Log" "GR RIFreg") scalar(Firms) indicate(`ind') b(2) se(2) sfmt(0) 
esttab `models' using $folder/TabA3_firststage_volumes_transform.tex, $esttab_rename_years keep(2008.year 2009.year 2010.year) $esttab_settings ///
mtitles("IHS" "Log" "GR RIFreg" "IHS" "Log" "GR RIFreg") scalar(Firms) indicate(`ind') b(2) se(2) sfmt(0) $esttab_tabularx replace

// Table A.4 Different specifications for loan volumes
loc models = "log1_vol_nace2_prices log1_vol_trend_prices log1_vol_nctr_prices log1_vol_lasso_prices log1_vol_allctrl_prices log1_vol_nace2 log1_vol_trend log1_vol_nctr log1_vol_lasso log1_vol_allctrl"
estfe `models', labels(firm_id "Firm" nace#year "time-4d NACE" nace2d#year "time-2d NACE" firm_id#c.year "Firm trend")
loc ind = r(indicate_fe)
esttab `models', $esttab_rename_years keep(2008.year 2009.year 2010.year) $esttab_settings ///
mtitles("2d Nace" "Trend" "No ctrl" "PDSLASSO" "All controls" "2d Nace" "Trend" "No ctrl" "PDSLASSO" "All controls") scalar(Firms tt_predictors y_predictors) indicate(`ind') b(2) se(2) sfmt(0)
esttab `models' using $folder/TabA4_firststage_volumes_robustness.tex, ///
$esttab_rename_years keep(2008.year 2009.year 2010.year) $esttab_settings  $esttab_tabularx replace ///
mtitles("2d Nace" "Trend" "No ctrl" "PDSLASSO" "All controls" "2d Nace" "Trend" "No ctrl" "PDSLASSO" "All controls") scalar(Firms tt_predictors y_predictors) indicate(`ind') b(2) se(2) sfmt(0)


******************************************************************************* 
// Main result interest rate
*******************************************************************************

cap gen interest_rate_orig = interest_rate
replace interest_rate = interest_rate_orig * 100

cap drop interest_rate_wns
winsor2 interest_rate if $sample & $period, cut(2.5 97.5) suff(_wns) by(year)
sum interest_rate_wns if $sample & (inPPI | inUHDM) & year == 2007, det

// Main figure
reghdfe interest_rate_wns ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("ir_ols")
reghdfe interest_rate_wns ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr nace#year) cl(cvrnr) 
/// NOTE: this regression was restricted with inPPI_2007 instead of inPPI in submitted version. As far as I can tell this changes nothing.
eststo_wrap, model("ir_ols_prices")

coefplot (ir_ols_prices, label("Firms in price data") offset(-0.1)) ///
 (ir_ols, label("All manufacturing firms")), ///
 $coefplot_settings keep(*.year#c.tt_uvall) rename(*.year#c.tt_uvall=.year *.year#c.tt_bvbid1=.year *.year#c.tt_bvbid6=.year) ytitle("Average interest rate") levels(95) ylabel(-0.4(0.2)1.2)
graph export $folder/Fig2b_firststage_interestrate.pdf, as(pdf) replace


******************************************************************************* 
// interest rate robustness tables
*******************************************************************************

reghdfe interest_rate_wns ib2007.year##c.tt_uvall if $period & $sample, abs(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("ir_noctrl")
reghdfe interest_rate_wns ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("ir_nace2")
reghdfe interest_rate_wns (2008.year 2009.year 2010.year)#c.tt_uvall $controls if $period & $sample, abs(cvrnr nace#year cvrnr##c.year) cl(cvrnr) nocons
eststo_wrap, model("ir_trend")
rlasso_fe if $sample & $period, y(interest_rate_wns) tt(tt_uvall) absorbtt(nace) absorbdid(cvrnr nace#year) x($pdslassox)
eststo_wrap, model("ir_lasso")
reghdfe interest_rate_wns ib2007.year##c.tt_uvall $allcontrols  if $period & $sample, abs(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("ir_allctrl")

reghdfe interest_rate_wns ib2007.year##c.tt_uvall if $period & $sample & (inPPI | inUHDM), abs(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("ir_noctrl_prices")
reghdfe interest_rate_wns ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr nace2d#year) cl(cvrnr)
eststo_wrap, model("ir_nace2_prices")
reghdfe interest_rate_wns (2008.year 2009.year 2010.year)#c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr nace#year cvrnr##c.year) cl(cvrnr) nocons
eststo_wrap, model("ir_trend_prices")
rlasso_fe if $sample & $period & (inPPI | inUHDM), y(interest_rate_wns) tt(tt_uvall) absorbtt(nace) absorbdid(cvrnr nace#year) x($pdslassox)
eststo_wrap, model("ir_lasso_prices")
reghdfe interest_rate_wns ib2007.year##c.tt_uvall $allcontrols if $period & $sample  & (inPPI | inUHDM), abs(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("ir_allctrl_prices")

// Table A.5 Different specifications for interest rates
loc models = "ir_ols_prices ir_trend_prices ir_noctrl_prices ir_lasso_prices ir_allctrl_prices ir_ols ir_trend ir_noctrl ir_lasso ir_allctrl"
estfe `models', labels(firm_id "Firm" nace#year "time-4d NACE" firm_id#c.year "Firm trend")
loc ind = r(indicate_fe)
esttab `models', $esttab_rename_years keep(2008.year 2009.year 2010.year) $esttab_settings ///
mtitles("Baseline" "Trend" "No ctrl" "PDSLASSO" "All controls" "Baseline"  "Trend" "No ctrl" "PDSLASSO" "All controls") scalar(Firms tt_predictors y_predictors) indicate(`ind') b(2) se(2) sfmt(0)
esttab `models' using $folder/TabA5_firststage_interestrate_robustness.tex, /// 
$esttab_rename_years keep(2008.year 2009.year 2010.year) $esttab_settings  $esttab_tabularx replace ///
mtitles("Baseline" "Trend" "No ctrl" "PDSLASSO" "All controls" "Baseline"  "Trend" "No ctrl" "PDSLASSO" "All controls") scalar(Firms tt_predictors y_predictors) indicate(`ind') b(2) se(2) sfmt(0)


******************************************************************************* 
// More detailed loan outcomes
********************************************************************************

* Figure 2c: Loans with relationships from pre-07 // there was a mistake here; fixed it. ( gen l1loans_pre07 = log(loans_pre07 + (loans_uv^2+1)^(1/2)))

cap drop l1loans_pre07
gen l1loans_pre07 = log(loans_pre07 + (loans_pre07^2+1)^(1/2))

reghdfe l1loans_pre07 ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr year#nace) cl(cvrnr)
eststo_wrap, model("log1_pre07")
reghdfe l1loans_pre07 ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr year#nace) cl(cvrnr)
eststo_wrap, model("log1_pre07_prices")

coefplot (log1_pre07_prices, offset(-0.1) label("Firms in price data")) ///
	(log1_pre07, label("All manufacturing firms")), ///
	$coefplot_settings_noalt keep(*.year#c.tt_uvall) rename($rename_list) ytitle("IHS of total balance of loans issued pre 2007") ylabel(-1.2(0.2)0.2, grid) levels(95)
graph export $folder/Fig2c_firststage_pre07vol.pdf, as(pdf) replace

* Figure 2d: New loans propensity
cap drop has_new_loans*
gen has_new_loans=loans_new>10 if !mi(loans_new)

reghdfe has_new_loans ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr year#nace) cl(cvrnr)
eststo_wrap, model("ols_newloans")
reghdfe has_new_loans ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr year#nace) cl(cvrnr)
eststo_wrap, model("ols_newloans_prices")

coefplot (ols_newloans_prices, offset(-0.1) label("Firms in price data")) ///
 (ols_newloans, label("All manufacturing firms")), ///
 $coefplot_settings_noalt keep(*.year#c.tt_uvall) rename($rename_list) ytitle("Probability to take out new loans > 100,000 DKK") levels(95) ylabel(-0.1(0.1)0.3, grid)
graph export  $folder/Fig2d_firststage_newloans.pdf, as(pdf) replace

* Figure 2e: Share of new loans
cap drop new_share
gen new_share = loans_new / loans_uv

reghdfe new_share ib2007.year##c.tt_uvall $controls if $period & $sample, abs(cvrnr year#nace) cl(cvrnr)
eststo_wrap, model("new_share")
eststo new_share_ppi: reghdfe new_share ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(cvrnr year#nace) cl(cvrnr)
eststo_wrap, model("new_share_prices")

coefplot (new_share_prices, offset(-0.1) label("Firms in price data")) ///
 (new_share, label("All manufacturing firms")), ///
 $coefplot_settings_noalt keep(*.year#c.tt_uvall) rename($rename_list) ytitle("Share of new loans in total loans") levels(95) ylabel(-0.1(0.05)0.2, grid)
graph export $folder/Fig2e_firststage_newloansshare.pdf, as(pdf) replace

* Figure 2f: Share of primary bank from 2007
cap drop pb_share
gen pb_share = loans_pb / loans_uv

reghdfe pb_share ib2007.year##c.tt_uvall $controls if $period & $sample, abs(firm_id year#nace) cl(cvrnr)
eststo_wrap, model("pb_share")
reghdfe pb_share ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), abs(firm_id year#nace) cl(cvrnr)
eststo_wrap, model("pb_share_prices")

coefplot (pb_share_prices, offset(-0.1) label("Firms in price data")) ///
	(pb_share, label("All manufacturing firms")), ///
	$coefplot_settings_noalt keep(*.year#c.tt_uvall) rename($rename_list) ytitle("Share of 2007 primary bank in total loans") levels(95)
graph export $folder/Fig2f_firststage_primarybankshare.pdf, as(pdf) replace
