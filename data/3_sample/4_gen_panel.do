/*
Used in:

- analysis/2_firststage/2_firststage_firmlevel.do
year nace nace2d firm_id interest_rate loans_uv06 loans_uv loans_uv07 loans_to_revenue07 jkod07 inPPI inUHDM tt_uvall stshare07 loans_to_revenue07 deposits_to_revenue07 interest_rate07 emp07 lemp07  ms_4d07  avg_wage07  firmage04  profit_to_revenue07  connections_loans07  connections_deposits07  inv_to_revenue07  equity_share07  pbshare07 revenue07  lrevenue07  equity_share07 profit_to_revenue07 loans_pre07 loans_new loans_pb

*/

global path = "$projectpath/data/3_sample"
cd $path

cap mkdir out
cap mkdir temp


********************************************************************************
* create yearly firm panel for non-price outcomes
********************************************************************************

*** start with full firm register
clear
forval year = 2003 / 2012 {
	append using $cleandatapath/FIRM/out/firm_nyvar_`year', keep(year cvrnr GF_NACE_DB07 JUR_VIRK_FORM GF_OMS GF_AARSV GF_ANSATTE GF_EGUL GF_AT GF_LGAG GF_RFEP GF_AARE GF_VTV)
}
rename GF_OMS revenue_firm
rename GF_AARSV fte_firm 
rename GF_ANSATTE emp_firm
rename GF_LGAG lgag_firm
rename GF_RFEP rfep_firm
rename GF_AARE aare_firm
rename GF_AT at_firm
rename GF_EGUL egul_firm

replace revenue_firm = revenue_firm / 1000
replace rfep_firm = rfep_firm / 1000
replace lgag_firm = lgag_firm / 1000
replace aare_firm = aare_firm / 1000
replace at_firm = at_firm / 1000
replace egul_firm = egul_firm / 1000

gegen firm_id = group(cvrnr)
xtset firm_id year

** Reduce to relevant sample and merge annual information from fire and urtevirk
merge m:1 cvrnr using $path/out/sample, keep(match) nogen


********************************************************************************
* merge partial panels
********************************************************************************

* urtevirk
merge 1:1 cvrnr year using $projectpath/data/1_combine_irtevirk_urtevirk/out/firm_panel, gen(_URTEVIRK_merge) keep(match master)

xtset firm_id year
cap drop interest_rate
gen interest_rate = interest / (0.5*L.loans_uv + 0.5*loans_uv)

foreach var of varlist loans_* interest_* {
	replace `var' = 0 if `var'==.
}
foreach var of varlist loans_* interest_* {
	replace `var' = 0 if `var' < 0
}

* fire
merge 1:1 cvrnr year using $cleandatapath/FIRE/out/fire, gen(_FIRE_merge2) keep(match master) keepus(elpr hlpr elul hlul uvbt rfep libe jkod besk lgag besk at past egul netsales akg alg kgl lgl rudg hens rfep udby tgt hens lgl kgl)

* fiks
merge 1:1 cvrnr year using $cleandatapath/FIKS/out/fiks_annual, keep(match master) keepus(SALG_IALT EKSPORT_IALT KOB_IALT) nogen
rename (SALG_IALT EKSPORT_IALT KOB_IALT) (revenue_fiks revenue_exp_fiks purchases_fiks)
gen revenue_dom_fiks = revenue_fiks - revenue_exp_fiks

* outcome variables: log levels
gen lliq = log(libe)
gen ldebtST = log(akg)
gen ldebt = log(akg + alg)
gen lloans = log(loans)
gen lloans_uv = log(loans_uv)
gen lloans_pb = log(loans_pb)
rename elul inv_goods
rename hlul inv_merch
rename uvbt inv_total
rename rfep profit
rename libe cash
rename egul equity
rename past liabilities
gen work_capital = inv_total + tgt - lgl - kgl
rename tgt receivables
gen payables = lgl + kgl
drop hens lgl kgl

* outcome variables: ratios
gen inv_output_to_rev = (inv_goods + inv_merch) / revenue_fiks07
gen inv_other_to_rev = (inv_total - inv_goods - inv_merch) / revenue_fiks07
gen inv_total_to_rev = inv_total / revenue_fiks07
gen inv_goods_to_rev = inv_goods / revenue_fiks07
gen inv_merch_to_rev = inv_merch / revenue_fiks07
foreach variable of varlist inv_*_to_rev {
	winsor2 `variable', cuts(1 99) replace
}
gen cash_to_rev = max(cash / revenue_fiks07, 0)
replace cash_to_rev = . if cash == .
gen equityshare = max(equity / liabilities, 0)
replace equityshare = . if equity == .
gen debt_to_rev = max((akg + alg) / revenue_fiks07, 0)
replace debt_to_rev = . if akg == .
gen credit_to_rev = max(loans_uv / revenue_fiks07, 0)
replace credit_to_rev = . if loans_uv == .
gen credit_to_at = max(loans_uv / at, 0)
replace credit_to_at = . if loans_uv == .

save $path/temp/panel, replace


********************************************************************************
*  attach market shares to 'panel'
********************************************************************************
* because I want them beyond 2012, need to first get firm-years for 2013+

use $cleandatapath/FIRM/out/firm_nyvar_2013, replace 
append using $cleandatapath/FIRM/out/firm_nyvar_2014
rename GF_OMS revenue_firm
replace revenue_firm = revenue_firm / 1000

merge 1:1 cvrnr year using $cleandatapath/FIKS/out/fiks_annual, keepus(SALG_IALT)
keep if inrange(year, 2013, 2014)
tab _merge
rename SALG_IALT revenue_fiks 
replace revenue_fiks = 0 if revenue_firm == 0 & revenue_fiks == .
keep cvrnr year revenue*
sort cvrnr year

merge m:1 cvrnr using $path/out/sample, keep(match) nogen
append using $path/temp/panel
drop firm_id 
egen firm_id = group(cvrnr)
xtset firm_id year

* now merge market size
merge m:1 nace year using $path/temp/marketsize, keep(match master)
tab nace _merge if year >= 2005 //nace codes 10-33 all complete 
drop _merge 
gen msfiksEU = revenue_fiks / market_eu28
save $path/out/panel, replace



