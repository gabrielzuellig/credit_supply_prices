global path = "$projectpath/analysis/7_agg_counterfact"
cd $path
cap mkdir $path/out
cap mkdir $folder


***********************************
** COUNTERFACTUAL ANALYSIS WITH OUR OWN PPI ESTIMATION SAMPLE, i.e. only domestic manufacturing
***********************************

* 1. Prepare
use $path/temp/panel_withcf, replace
merge m:1 nace2d using $path/temp/indweights_dst09, keep(match master)
keep if dP_cfA ~= . 
gen firmw = revenue_fiks
replace firmw = 0 if firmw < 0

* 2. Industry-wide price changes and indices 
collapse (firstnm) nace2 indw* firmw (mean) dP dP_cfA*, by(cvrnr tq)
collapse (firstnm) indw* (mean) dP* [aw=firmw], by(nace2 tq) 
foreach v of varlist dP*{
	local Psname = substr("`v'", 2, .)
	qui gen `Psname' = 0 if tq == tq(2007,4)
	sort nace2 tq 
	qui by nace2: replace `Psname' = `Psname'[_n-1] + `v' if tq > tq(2007,4)
	gsort nace2 -tq 
	qui by nace2: replace `Psname' = `Psname'[_n-1] - `v'[_n-1] if tq < tq(2007,4)
	qui replace `Psname' = exp(`Psname')
}
sort nace2 tq

* 3. Laspeyres (artihmetic avg) index across industries (using fixed weights)
collapse (mean) P* [aw=indw_dst09_dommanu], by(tq)
tsset tq
foreach v of varlist P*{
	qui replace `v' = log(`v')
}

* 4. ad official DST indices
merge 1:1 tq using $path/temp/dst_series, keep(match master) nogen

* 5. figure
graph twoway (rarea P_cfA_1 P_cfA_2 tq if inrange(tq, tq(2007,1), tq(2011,2)), color(gs14) lcolor(gs14)) ///
	(line P_cfA tq if inrange(tq, tq(2007,1), tq(2011,2)), lp(dash) lcolor(maroon)) ///
	(line P tq if inrange(tq, tq(2007,1), tq(2011,2)), lp(solid) lcolor(navy)) ///
	(line ppi_dstmanu tq if inrange(tq, tq(2007,1), tq(2011,2)), lcolor(gs5) lp(shortdash)), ///
	legend(r(3) order(3 "Observed prices, selected sample" 2 "Counterfactual: no loan supply shock" 4 "Official manufacturing price index")) ///
	xtitle("") ytitle("log prices [2007q4 = 0]") xsc(r(188 204)) ysc(r(-.04 .08)) xlab(188(4)204) ylab(-.04(.02).08)
graph export $path/out/Fig6_counterfactual_A.pdf, as(pdf) replace



***********************************
** Long chained index (for VAR)
***********************************

* 1. Prepare
use $path/temp/panel_withcf, replace
merge m:1 nace2d using $path/temp/indweights_dst09, keep(match master)
gen firmw = revenue_fiks
gen hasfirmw = firmw ~= .
tabstat hasfirmw, by(year)
bys cvrnr (year): egen meanfirmw = mean(firmw)
replace firmw = meanfirmw if firmw == .
replace hasfirmw = firmw ~= .
tabstat hasfirmw, by(year)
tab nace2d hasfirmw, m

* 2. Firm and then industry-wide price changes and indices 
collapse (firstnm) nace2 indw* firmw (mean) dP, by(cvrnr tq)
bys nace2d tq: egen sumw = total(firmw)
replace firmw = firmw/sumw
collapse (firstnm) indw* (mean) dP* [aw=firmw], by(nace2 tq)
foreach v of varlist dP*{
	local Psname = substr("`v'", 2, .)
	qui gen `Psname' = 0 if tq == tq(2007,4)
	sort nace2 tq 
	qui by nace2: replace `Psname' = `Psname'[_n-1] + `v' if tq > tq(2007,4)
	gsort nace2 -tq 
	qui by nace2: replace `Psname' = `Psname'[_n-1] - `v'[_n-1] if tq < tq(2007,4)
	qui replace `Psname' = exp(`Psname')
}
sort nace2 tq

* 3. Laspeyres (artihmetic avg) index across industries (using fixed weights)
collapse (mean) P* [aw=indw_dst09_dommanu], by(tq)
foreach v of varlist P*{
	qui replace `v' = log(`v')
}

graph twoway (line P tq)

* export
gen PPImicro = exp(P)
keep tq PPImicro
save $path/out/PPImicro, replace 
list tq PPImicro
