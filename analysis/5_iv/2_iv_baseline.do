/*

	2_IV_BASELINE:
	
	This file takes the PPI data, appends it with the trade unit value data 
	and performs IV estimations (Section IV)

	DEPENDENCIES:
	
	Inputs:
	- $path/temp/panel.dta

	- $projectpath/data/3_sample/out/panel.dta   
	
	- $path/../4_did_uhdm/temp/panel.dta

	Outputs:
	 - Tab 2

*/


global path = "$projectpath/analysis/5_iv"
cd $path
cap mkdir $path/out

/*******************************************************************************
Programs
********************************************************************************/

* twosample IV. Absorb controls, only works with 1 endogenous variable and one instrument and no exogenous variables.
cap program drop ts2iv
program ts2iv, eclass

_iv_parse `0' 
loc lhs = "`s(lhs)'"
loc endog = "`s(endog)'"
loc exog = "`s(exog)'"
loc inst = "`s(inst)'"

local 0 = "`s(zero)'"
syntax [if] [aweight], sample(varname) [output(string) firstopt(string) secondopt(string) firstif(string) secondif(string)] *


if "`weight'" != "" {
	loc weight = "[`weight'`exp']"
}
else {
	loc weight = ""
}
if "`output'" == "" {
	loc output = "qui"
}

sca kx=1
sca ke=`:word count `exog''+1

if "`if'" == "" {
	loc if = "if 1"
}

if "`output'" == "noisily" {
	di "reghdfe `endog' `inst' `exog' `if' & `firstif', `options'"
}
`output' reghdfe `endog' `inst' `exog' `if' & `firstif', `options' `firstopt'
mat Vx = e(V)

loc F = (_b[`inst'] / _se[`inst'])^2
loc Fp = 2 * ttail(e(df_r), abs(_b[`inst'] / _se[`inst']))
loc N1 = e(N)

tempvar xh
predict `xh', xb

if "`output'" == "noisily" {
	di "reghdfe `lhs' `inst' `exog' `weight' `if' & `secondif', `options'"
}
`output' reghdfe `lhs' `inst' `exog'  `weight' `if' & `secondif', `options' `secondopt'
mat Vy = e(V) * e(df_r) / e(N)

if "`output'" == "noisily" {
	di "reghdfe `lhs' `xh' `exog' `if' & `secondif', `options'"
}
`output' reghdfe `lhs' `xh' `exog'  `weight' `if' & `secondif', `options' `secondopt'
mat b2s = e(b)
mat b2sx = b2s[1,1]'
loc dof = e(df_r)
loc N = e(N)
gdistinct cvrnr if e(sample)
loc Firms = r(ndistinct)

if "`output'" == "noisily" {
	di "reghdfe `inst' `xh' `exog' `if' & `secondif', `options'"
}
`output' reghdfe `inst' `xh' `exog'  `weight' `if' & `secondif', `options' `secondopt'
mat ch = e(b)'
mat ch = ch,(J(kx,ke,0)\I(ke))

mat var1het1 = ch*Vy*ch' 
mat var1het2 = (b2sx' # ch) * Vx * (b2sx # ch')
mat var1het = var1het1 + var1het2
mat se = vecdiag(cholesky(diag(vecdiag(var1het))))

mat b = b2s
mat V = var1het
loc allnames = "`endog' `exog' _cons"
matname b `allnames', c(.)
matrix rownames V = `allnames'
matrix colnames V = `allnames'
matrix rownames V = _:
matrix colnames V = _:

ereturn clear
ereturn post b V, depname(`lhs') dof(`dof') obs(`N')
ereturn scalar rkf = `F'
ereturn scalar rkfp = `Fp'
ereturn scalar Firms = `Firms'
ereturn scalar N1 = `N1'
ereturn display

end

* ivreghdfe with fgls weights
cap program drop ivfreghdfe
program def ivfreghdfe
	syntax anything [if], [iterate(int 5)] *
	cap drop tempw
	gen tempw = 1
	forval i = 1/`iterate' {
		cap drop resids
		qui ivreghdfe `anything' [aw = tempw] `if', `options' resid(resids)
		cap drop tempw
		cap drop tempsd
		qui gegen tempsd = sd(resids) if e(sample), by(panid)
		replace tempsd = 0.05 if tempsd<0.05
		qui gen tempw = 1/tempsd^2
	}
	cap drop finalw
	gen finalw = tempw
	ivreghdfe `anything'  [aw = tempw] `if', `options'
	cap drop tempw
end


********************************************************************************
* prep
********************************************************************************
use $path/temp/panel, clear

tostring cvrnr, gen(cvrstr)
gen cvrno = cvrnr
drop cvrnr
gen cvrnr = cvrstr

* append firm level sample
append using $projectpath/data/3_sample/out/panel, gen(firm_lvl_panel)
destring cvrnr, replace
drop if jkod07=="R"

* ppi part runs with these variables
keep tt_uvall nace nace2d loans_uv07 loans_uv06 loans_to_revenue07 deposits_to_revenue07 stshare07 interest_rate07 emp07 lemp07 revenue07 lrevenue07 equity_share07 profit_to_revenue07 ms_4d07 avg_wage07 firmage04 connections_loans07 connections_deposits07 inv_to_revenue07 pbshare07 tq year cvrnr hs6 panid nationtype prisadj2 firm_lvl_panel lloans_uv loans_uv jkod07


gen sample = 1 if firm_lvl_panel == 1
replace sample = 2 if firm_lvl_panel == 0

winsor2 interest_rate07 loans_to_revenue07 deposits_to_revenue07, cut(2 98) replace by(sample)

gen th = yh(year,halfyear(dofq(tq)))
cap gen lprisadj2 = log(prisadj2)

label variable lloans_uv "Log loans"

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

foreach var in loans_uv {
	cap drop l`var'
	cap drop l1`var'
	gen l`var' = log(`var')
	gen l1`var' = log(`var' + (`var'^2+1)^(1/2))
	cap drop `var'_gr
	cap drop `var'_gr2
	cap drop `var'_gr3
	cap drop `var'_gr_wns
	cap drop `var'07
	gegen `var'07 = max(`var'*(year==2007)), by(cvrnr)
	gen `var'_gr = `var' / `var'07 - 1
}

cap drop tmp lloans_uv08
gen tmp = lloans_uv if year == 2008
egen lloans_uv08 = max(tmp), by(cvrnr)
replace lloans_uv08 = lloans_uv if year<2008
label variable lloans_uv08 "log loans"

cap drop tmp 
cap drop l1loans_uv08
gen tmp = l1loans_uv if year == 2008
egen l1loans_uv08 = max(tmp), by(cvrnr)
replace l1loans_uv08 = l1loans_uv if year<2008

cap drop tt ia_*
gen tt = tt_uvall * (year != 2007)
gen ia_loans = loans_to_revenue07 * (year != 2007)
gen ia_deposits = deposits_to_revenue07 * (year != 2007)
gen ia_stshare = stshare07 * (year != 2007)
gen ia_ir = interest_rate07 * (year != 2007)


********************************************************************************
* PPI: Baseline
********************************************************************************

global sample2 = "has_2007 & has_2008 & has_2009 & has_2010 & loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01 & inrange(nace2d,10,33) & nationtype==2 & sample == 2"

reghdfe lprisadj2 lloans_uv08 ia_loans ia_deposits ia_stshare ia_ir if $sample2 & (year==2007 | year==2008), absorb(panid th#nace) cl(cvrnr)
eststo_wrap, model("ols_ppi_2008")
reghdfe lprisadj2 lloans_uv08 ia_loans ia_deposits ia_stshare ia_ir  if $sample2 & (year==2007 | year==2009), absorb(panid th#nace) cl(cvrnr)
eststo_wrap, model("ols_ppi_2009")
reghdfe lprisadj2 lloans_uv08 ia_loans ia_deposits ia_stshare ia_ir  if $sample2 & (year==2007 | year==2010), absorb(panid th#nace) cl(cvrnr)
eststo_wrap, model("ols_ppi_2010")

ivreghdfe lprisadj2 (lloans_uv08 = tt) ia_loans ia_deposits ia_stshare ia_ir if $sample2 & (year==2007 | year==2008), absorb(panid th#nace) cl(cvrnr) first ffirst savefirst
eststo_ivwrap, model("ppi_2008")
ivreghdfe lprisadj2 (lloans_uv08 = tt)  ia_loans ia_deposits ia_stshare ia_ir if $sample2 & (year==2007 | year==2009), absorb(panid th#nace) cl(cvrnr) first
eststo_ivwrap, model("ppi_2009")
ivreghdfe lprisadj2 (lloans_uv08 = tt)  ia_loans ia_deposits ia_stshare ia_ir  if $sample2 & (year==2007 | year==2010), absorb(panid th#nace) cl(cvrnr) first
eststo_ivwrap, model("ppi_2010")


********************************************************************************
* PPI: Two sample IV
********************************************************************************

// sample restrictions for firm level sample
global sample1 = "loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01 & inrange(nace2d,10,33) & sample==1"
global one = "1==1"

reghdfe lloans_uv08 tt ia_loans ia_deposits ia_stshare ia_ir if sample==1 & $sample1 & inlist(year, 2007, 2008), abs(cvrnr nace#year) cl(cvrnr)
sum lloans_uv08 if sample == 1, det

* tsiv full sample
ts2iv lprisadj2 (lloans_uv08 = tt) ia_loans ia_deposits ia_stshare ia_ir if $one, firstopt(abs(cvrnr nace#year)) secondopt(abs(panid nace#th)) cl(cvrnr) sample(sample) output(noisily) firstif($sample1 & inlist(year, 2007, 2008)) secondif($sample2 & inlist(year, 2007, 2008))
eststo_wrap, model("ppi_ts_2008")
ts2iv lprisadj2 (lloans_uv08 = tt) ia_loans ia_deposits ia_stshare ia_ir if $one, firstopt(abs(cvrnr nace#year)) secondopt(abs(panid nace#th)) cl(cvrnr) sample(sample) firstif($sample1 & inlist(year, 2007, 2008)) secondif($sample2 & inlist(year, 2007, 2009))
eststo_wrap, model("ppi_ts_2009")
ts2iv lprisadj2 (lloans_uv08 = tt) ia_loans ia_deposits ia_stshare ia_ir if $one, firstopt(abs(cvrnr nace#year)) secondopt(abs(panid nace#th)) cl(cvrnr) sample(sample) firstif($sample1 & inlist(year, 2007, 2008)) secondif($sample2 & inlist(year, 2007, 2010))
eststo_wrap, model("ppi_ts_2010")

esttab ols_ppi_2008 ols_ppi_2009 ols_ppi_2010 , keep(l*loans_uv*) star(* 0.1 ** 0.05 *** 0.01) stats(N Firms rkf rkfp) se
esttab ppi_2008 ppi_2009 ppi_2010 , keep(l*loans_uv*) star(* 0.1 ** 0.05 *** 0.01) stats(N Firms rkf rkfp) se
esttab ppi_ts_2008 ppi_ts_2009 ppi_ts_2010, keep(l*loans_uv*) star(* 0.1 ** 0.05 *** 0.01) stats(N Firms rkf rkfp) se

********************************************************************************
********************************************************************************
* UHDM
* Important: IVREGHDFE HAS A BUG AND IGNORES WEIGHTS WHEN COMPUTING FIXED EFFECTS BEFORE VERSION 1.2.
* Below we force use the patched version, instead of the system installed older one.
********************************************************************************
********************************************************************************

use $path/../4_did_uhdm/temp/panel, clear

append using $projectpath/data/3_sample/out/panel, gen(firm_lvl_panel)
destring cvrnr, replace

* 
keep tt_uvall nace nace2d loans_uv07 loans_uv06 loans_to_revenue07 deposits_to_revenue07 stshare07 interest_rate07 emp07 lemp07 revenue07 lrevenue07 equity_share07 profit_to_revenue07 ms_4d07 avg_wage07 firmage04 connections_loans07 connections_deposits07 inv_to_revenue07 pbshare07 year cvrnr panid  firm_lvl_panel lloans_uv loans_uv luv1 jkod07 has_2005  has_2006  has_2007  has_2008 has_2009 has_2010


gen sample = 1 if firm_lvl_panel == 1
replace sample = 2 if firm_lvl_panel == 0

winsor2 interest_rate07 loans_to_revenue07 deposits_to_revenue07, cut(2 98) replace by(sample)

drop if jkod07 == "R"

cap drop lloans_uv 
gen lloans_uv = log(loans_uv)
cap drop l1loans_uv 
gen l1loans_uv = log(loans_uv+(1+loans_uv^2)^(1/2))

cap drop tmp 
cap drop lloans_uv08
gen tmp = lloans_uv if year == 2008
egen lloans_uv08 = max(tmp), by(cvrnr)
replace lloans_uv08 = lloans_uv if year<2008

cap gegen panid = group(cvrnr CN2)
cap destring nace, replace
cap destring cvrnr
cap gen CN2 = real(substr(CN4,1,2))
cap destring CN*, replace

cap drop tt ia_*
gen tt = tt_uvall * (year != 2007)
gen ia_loans = loans_to_revenue07 * (year != 2007)
gen ia_deposits = deposits_to_revenue07 * (year != 2007)
gen ia_stshare = stshare07 * (year != 2007)
gen ia_ir = interest_rate07 * (year != 2007)


********************************************************************************
* baseline graph and tables
********************************************************************************

global controls = "ib2007.year##c.loans_to_revenue07 ib2007.year##c.deposits_to_revenue07 ib2007.year##c.stshare07 ib2007.year##c.interest_rate07"
global sample2 = "loans_to_revenue07>0.01 & loans_uv07>100 & loans_uv06>100 & has_2005 & has_2006 & has_2007 & has_2008 & has_2009 & has_2010 & (inrange(nace2d,10,33)) & sample == 2"
global period = "inrange(year, 2005, 2010)"

********************************************************************************

freghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample2, absorb(panid year#nace) cl(cvrnr)

reghdfe luv1 lloans_uv08 2008.year#($controls) [aw=finalw] if $sample2 & (year==2007 | year==2008), absorb(panid year#nace) cl(cvrnr)
eststo_wrap, model("ols_UHDM_2008")
reghdfe luv1 lloans_uv08 2009.year#($controls) [aw=finalw] if $sample2 & (year==2007 | year==2009), absorb(panid year#nace) cl(cvrnr)
eststo_wrap, model("ols_UHDM_2009")
reghdfe luv1 lloans_uv08 2010.year#($controls) [aw=finalw] if $sample2 & (year==2007 | year==2010), absorb(panid year#nace) cl(cvrnr)
eststo_wrap, model("ols_UHDM_2010")

ivreghdfe_wfix luv1 (lloans_uv08 = tt) ia_loans ia_deposits ia_stshare ia_ir [aw=finalw] if $sample2 & (year==2007 | year==2008), absorb(panid year#nace) cl(cvrnr) first
eststo_ivwrap, model("UHDM_2008")
ivreghdfe_wfix luv1 (lloans_uv08 = tt) ia_loans ia_deposits ia_stshare ia_ir [aw=finalw] if $sample2 & (year==2007 | year==2009), absorb(panid year#nace) cl(cvrnr) first
eststo_ivwrap, model("UHDM_2009")
ivreghdfe_wfix luv1 (lloans_uv08 = tt) ia_loans ia_deposits ia_stshare ia_ir [aw=finalw] if $sample2 & (year==2007 | year==2010), absorb(panid year#nace) cl(cvrnr) first
eststo_ivwrap, model("UHDM_2010")


********************************************************************************
* twosample IV
********************************************************************************

global sample1 = "loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01 & inrange(nace2d,10,33) & sample == 1"

ts2iv luv1 (lloans_uv08 = tt) ia_loans ia_deposits ia_stshare ia_ir [aweight = finalw] if $one, firstopt(abs(cvrnr nace#year)) secondopt(abs(panid nace#year)) cl(cvrnr) sample(sample) output(noisily) firstif($sample1 & inlist(year, 2007, 2008)) secondif($sample2 & inlist(year, 2007, 2008))
eststo_wrap, model("uhdm_ts_2008")
ts2iv luv1 (lloans_uv08 = tt) ia_loans ia_deposits ia_stshare ia_ir [aweight = finalw] if $one, firstopt(abs(cvrnr nace#year)) secondopt(abs(panid nace#year)) cl(cvrnr) sample(sample) output(noisily) firstif($sample1 & inlist(year, 2007, 2008)) secondif($sample2 & inlist(year, 2007, 2009))
eststo_wrap, model("uhdm_ts_2009")
ts2iv luv1 (lloans_uv08 = tt) ia_loans ia_deposits ia_stshare ia_ir [aweight = finalw]  if $one, firstopt(abs(cvrnr nace#year)) secondopt(abs(panid nace#year)) cl(cvrnr) sample(sample) output(noisily) firstif($sample1 & inlist(year, 2007, 2008))  secondif($sample2 & inlist(year, 2007, 2010))
eststo_wrap, model("uhdm_ts_2010")

esttab ols_UHDM_2008 ols_UHDM_2009 ols_UHDM_2010 UHDM_2008 UHDM_2009 UHDM_2010 uhdm_ts_2008 uhdm_ts_2009 uhdm_ts_2010, keep(lloans_uv08) star(* 0.1 ** 0.05 *** 0.01) stats(rkf N Firms)


********************************************************************************
* Tables
********************************************************************************

esttab ols_ppi_2008 ols_ppi_2009 ols_ppi_2010 ols_UHDM_2008 ols_UHDM_2009 ols_UHDM_2010, keep(lloans_uv08) star(* 0.1 ** 0.05 *** 0.01) stats(N Firms, fmt(0 0)) b(3) se(3)
esttab ppi_2008 ppi_2009 ppi_2010 UHDM_2008 UHDM_2009 UHDM_2010, keep(lloans_uv08) star(* 0.1 ** 0.05 *** 0.01) stats(rkf rkfp arf arfp N Firms, fmt(3 3 3 3 0 0)) b(3) se(3)
esttab ppi_ts_2008 ppi_ts_2009 ppi_ts_2010 uhdm_ts_2008 uhdm_ts_2009 uhdm_ts_2010, keep(lloans_uv08) star(* 0.1 ** 0.05 *** 0.01) stats(rkf rkfp N Firms, fmt(3 3 0 0))  b(3) se(3)

esttab ols_ppi_2008 ols_ppi_2009 ols_ppi_2010 ols_UHDM_2008 ols_UHDM_2009 ols_UHDM_2010 using $path/out/Tab2_table_iv, booktabs replace fragment keep(lloans_uv08) star(* 0.1 ** 0.05 *** 0.01) stats(N Firms, fmt(0 0)) b(3) se(3)
esttab ppi_2008 ppi_2009 ppi_2010 UHDM_2008 UHDM_2009 UHDM_2010 using $path/out/Tab2_table_iv, booktabs append fragment keep(lloans_uv08) star(* 0.1 ** 0.05 *** 0.01) stats(rkf rkfp arf arfp N Firms, fmt(3 3 3 3 0 0)) b(3) se(3)
esttab ppi_ts_2008 ppi_ts_2009 ppi_ts_2010 uhdm_ts_2008 uhdm_ts_2009 uhdm_ts_2010 using $path/out/Tab2_table_iv, booktabs append fragment keep(lloans_uv08) star(* 0.1 ** 0.05 *** 0.01) stats(rkf rkfp N Firms, fmt(3 3 0 0))  b(3) se(3)

