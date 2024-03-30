/*

	1_DID_FIRMOUTCOMES:
	
	This file estimates other firm-level outcomes presented in Section V 
	(and referenced appendices)

	DEPENDENCIES:
	
	Inputs:
	 - data/3_sample/out/panel.dta, of which the following variables (exhaustive)
	   cvrnr year nace loans_uv06 loans_uv07 loans_to_revenue07 stshare07 loans_to_revenue07 
	   deposits_to_revenue07 interest_rate07 revenue_fiks revenue_dom_fiks revenue_exp_fiks 
	   inPPI inUHDM fte_firm rfep_firm lgag_firm purchases_fiks interest_uv inv_goods 
	   elul07 inv_total msfiksEU tt_uvall
	 - data/4_demand_elasticities/out/firmlvl_DE_allcvrnr.dta, of which the following variables (exhaustive)
	   sigmaBW_firmlvl 
	 
	Outputs:
	 - Fig 5a-5b 
	 - Tab A.10
	 - Fig A.7a-A.7b

*/


global path = "$projectpath/analysis\6_did_firm_outcomes"
cd $path
cap mkdir out
global folder = "$path/out"


********************************************************************************
* settings (as usual)
********************************************************************************

global period = "year>2004 & year<2011"
global period2 = "year>2004 & year<2015"
global sample = "loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01"
global controls = "ib2007.year##c.stshare07 ib2007.year##c.loans_to_revenue07 ib2007.year##c.deposits_to_revenue07 ib2007.year##c.interest_rate07"

********************************************************************************
* data prep
********************************************************************************

use $projectpath/data/3_sample/out/panel.dta, replace
merge m:1 cvrnr using $projectpath/data/5_demand_elasticities/out/firmlvl_DE_allcvrnr, keep(match master) nogen

keep cvrnr year nace loans_uv06 loans_uv07 loans_to_revenue07 stshare07 loans_to_revenue07 deposits_to_revenue07 interest_rate07 revenue_fiks revenue_dom_fiks revenue_exp_fiks inPPI inUHDM fte_firm rfep_firm lgag_firm purchases_fiks interest_uv inv_goods elul07 inv_total msfiksEU tt_uvall sigmaBW_firmlvl

// unique firm indicator
bys cvrnr (year): gen uniquefirm = _n == 1

// logs
cap gen lrevenue_fiks = log(revenue_fiks)
cap gen lrevenue_fiks_exp = log(revenue_exp_fiks)
cap gen lrevenue_fiks_dom = log(revenue_dom_fiks)
cap gen lpurchases = log(purchases_fiks)
cap gen llgag_firm = log(lgag_firm)
cap gen lemp = log(fte_firm)
cap drop lrevenue_per_worker
gen lrevenue_per_worker = log(revenue_fiks / fte_firm)

// ratios and markup stuff
cap drop profit_to_revenue_fiks
gen profit_to_revenue_fiks = rfep_firm / revenue_fiks
gen grossopmargin1 = ( revenue_fiks - lgag_firm - purchases_fiks ) / revenue_fiks
gen grossopmargin2 = ( revenue_fiks - lgag_firm - purchases_fiks - interest_uv ) / revenue_fiks

// winsorizing 
winsor2 grossopmargin1, cuts(0.5 99.5) by(year) suffix(_winsall)
winsor2 grossopmargin1 if $period & $sample & (inPPI | inUHDM), cut(0.5 99.5) by(year) replace
winsor2 grossopmargin2, cuts(0.5 99.5) by(year) suffix(_winsall)
winsor2 grossopmargin2 if $period & $sample & (inPPI | inUHDM), cut(0.5 99.5) by(year) replace
winsor2 profit_to_revenue_fiks, cuts(2 98) by(year) suffix(_winsall)
winsor2 profit_to_revenue_fiks if $period & $sample & (inPPI | inUHDM), cut(2 98) by(year) replace

// has-variables
cap drop has_*
forval year = 2005 / 2014 {
	gegen has_`year' = max((year==`year')*(revenue_fiks>0)), by(cvrnr)
}
global survival = "has_2005 & has_2006 & has_2007 & has_2008 & has_2009 & has_2010"
global survival_long = "has_2005 & has_2006 & has_2007 & has_2008 & has_2009 & has_2010 & has_2011 & has_2012 & has_2013 & has_2014"

// inventories
sum inv_goods, det // many NAs, > 25% zeros
gen nonNA_inv_goods = inv_goods ~= .
bys cvrnr (year): egen yearsNonNA_inv_goods = total(nonNA_inv_goods)
gen between0312 = inrange(year, 2003, 2012)
bys cvrnr (year): egen yearsBetween0312 = total(between0312)
gen sharenonNA_inv_goods = yearsNonNA_inv_goods / yearsBetween0312
tab sharenonNA_inv_goods if uniquefirm == 1
gen inventsample50_goods = 0
replace inventsample50_goods = 1 if elul07 ~= . & sharenonNA_inv_goods >= .5
distinct cvrnr if inventsample50_goods == 1 
gen l1inv_goods = log(inv_goods+(1+inv_goods^2)^(1/2))
gen linv_total = log(inv_total)

// market share
gen lmsfiksEU = log(msfiksEU)
winsor2 lmsfiksEU, cuts(5 95) by(year) suff(_wins)

// demand elasticities
egen highsigma = cut(sigmaBW_firmlvl), at(0 2.4 200) icodes

// labelling 
label def y 2008 "2008" 2009 "2009" 2010 "2010", replace
label values year y


********************************************************************************
* sales
********************************************************************************

// total sales
reghdfe lrevenue_fiks ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("revenue_prices")

// domestic vs. exports
reghdfe lrevenue_fiks_dom ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("revenue_dom_prices")

reghdfe lrevenue_fiks_exp ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("revenue_exp_prices")


********************************************************************************
* Profitability
********************************************************************************

// sales / workers
reghdfe lrevenue_per_worker ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("revenue_pw_prices")

// (sales - labor - material cost) / sales
reghdfe grossopmargin1 ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("gropm1_prices")

// (sales - labor - material cost - interest expenses from URTEVIRK) / sales
reghdfe grossopmargin2 ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("gropm2_prices")

// EBIT over sales 
reghdfe profit_to_revenue_fiks ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("profitabreg_prices")

// figure 5a
coefplot (revenue_pw_prices, label("Sales per worker") offset(-0.1) levels(95)) ///
	(gropm1_prices, label("Gross profit margin") offset(0) levels(95)), ///
	keep(*.year#c.tt_uvall) rename(*.year#c.tt_uvall=.year) ///
	$coefplot_settings ytitle("Profitability ratios") legend(r(1)) ysc(r(-.05 .125)) ylab(-.05(0.05)0.1)
graph export $folder/Fig5a_profit_ratios.pdf, as(pdf) replace
	
	
********************************************************************************
* market share relative to entire EU
* IMPORTANT: $survival_long is not defined
********************************************************************************

reghdfe lmsfiksEU_wins ib2007.year##c.tt_uvall $controls if $period2 & $sample & (inPPI | inUHDM) & $survival_long, absorb(cvrnr nace#year) vce(cl cvrnr)
eststo_wrap, model("marketshare_prices_survival")

// figure 5b
coefplot (marketshare_prices_survival, label("Mean (OLS)") offset(0) levels(95)), ///
	keep(*.year#c.tt_uvall) rename(*.year#c.tt_uvall=.year) ///
	$coefplot_settings ytitle("Market share in European Union (%)") legend(off)
graph export $folder/Fig5b_market_share.pdf, as(pdf) replace

********************************************************************************
* labor input 
********************************************************************************

reghdfe llgag_firm ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("laborcost_prices")

reghdfe lemp ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("employment_prices")

********************************************************************************
* inventories
********************************************************************************

reghdfe linv_total ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("linv_total")

reghdfe l1inv_goods ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("inventory_finalgoods")

reghdfe l1inv_goods ib2007.year##c.tt_uvall $controls if $period & $sample & (inPPI | inUHDM) & inventsample50_goods == 1, absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("inventory_finalgoods_bal50")
	
********************************************************************************
* print baseline table (A.10)
********************************************************************************

* 1st panel
esttab revenue_pw_prices gropm1_prices gropm2_prices revenue_prices revenue_dom_prices revenue_exp_prices, ///
	rename(2008.year#c.tt_uvall 2008 2009.year#c.tt_uvall 2009 2010.year#c.tt_uvall 2010) keep(2008 2009 2010) mtitles("Sales per worker" "Gross op. margin" "--, excl. int. paym." "Sales" "Dom. sales" "Exports") scalar(Firms) indicate("time-4d NACE = _cons") $esttab_settings b(3) se(3) sfmt(0 2) ti("Other firm outcomes")
	
esttab revenue_pw_prices gropm1_prices gropm2_prices revenue_prices revenue_dom_prices revenue_exp_prices using $path/out/TabA10_other_firm_outcomes_panel1.tex, ///
	rename(2008.year#c.tt_uvall 2008 2009.year#c.tt_uvall 2009 2010.year#c.tt_uvall 2010) keep(2008 2009 2010) mtitles("Sales per worker" "Gross op. margin" "--, excl. int. paym." "Sales" "Dom. sales" "Exports") scalar(Firms) indicate("time-4d NACE = _cons") $esttab_settings b(3) se(3) sfmt(0 2) ti("Other firm outcomes") replace

* 2nd panel
esttab laborcost_prices employment_prices profitabreg_prices linv_total inventory_finalgoods inventory_finalgoods_bal50, ///
	rename(2008.year#c.tt_uvall 2008 2009.year#c.tt_uvall 2009 2010.year#c.tt_uvall 2010) keep(2008 2009 2010) mtitles("Labor cost" "Employment" "Profits to sales" "Total inventories" "Good inventories" "--, more balanced") scalar(Firms) indicate("time-4d NACE = _cons") $esttab_settings b(3) se(3) sfmt(0 2) ti("Other firm outcomes")
	
esttab laborcost_prices employment_prices profitabreg_prices linv_total inventory_finalgoods inventory_finalgoods_bal50 using $path/out/TabA10_other_firm_outcomes_panel2.tex, ///
	rename(2008.year#c.tt_uvall 2008 2009.year#c.tt_uvall 2009 2010.year#c.tt_uvall 2010) keep(2008 2009 2010) mtitles("Labor cost" "Employment" "Profits to sales" "Total inventories" "Good inventories" "--, more balanced") scalar(Firms) indicate("time-4d NACE = _cons") $esttab_settings b(3) se(3) sfmt(0 2) ti("Other firm outcomes") replace	
	

********************************************************************************
* high vs. low demand elasticity
********************************************************************************	

// wage bill
reghdfe llgag_firm ib2007.year##c.tt_uvall#ibn.highsigma $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("laborcost_bysigma")

coefplot (laborcost_bysigma, label("Low demand elasticity") offset(0) keep(*.year#0.highsigma#c.tt_uvall)) ///
	(laborcost_bysigma, label("High demand elasticity") offset(.1) keep(*.year#1.highsigma#c.tt_uvall)), ///
	rename(*.year#0.highsigma#c.tt_uvall=.year *.year#1.highsigma#c.tt_uvall=.year) ///
	$coefplot_settings ytitle("Log labor cost")
graph export $folder/FigA7a_labor_cost_bysigma.pdf, as(pdf) replace

// gross operating margin
reghdfe grossopmargin1 ib2007.year##c.tt_uvall#ibn.highsigma $controls if $period & $sample & (inPPI | inUHDM), absorb(cvrnr nace#year) cl(cvrnr)
eststo_wrap, model("grossopmargin1_bysigma")

coefplot (grossopmargin1_bysigma, label("Low demand elasticity") offset(0) keep(*.year#0.highsigma#c.tt_uvall)) ///
	(grossopmargin1_bysigma, label("High demand elasticity") offset(0.1) keep(*.year#1.highsigma#c.tt_uvall)), ///
	rename(*.year#0.highsigma#c.tt_uvall=.year *.year#1.highsigma#c.tt_uvall=.year) ///
	$coefplot_settings ytitle("Gross operating margin")
graph export $folder/FigA7b_gross_op_margin1_bysigma.pdf, as(pdf) replace
	
	