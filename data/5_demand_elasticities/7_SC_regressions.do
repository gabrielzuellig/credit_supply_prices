/*

	7_SC_regressions:
	
	This file runs pass-through regressions for the whole sample and by CN2 category.
	
	DEPENDENCIES:
	
	Inputs:
	
	 - data/5_demand_elasticities/temp/data_y
	 
	Outputs:
	 
	 - data/5_demand_elasticities/out/betaSC_by_CN2
	 
	 - Tab C.2

*/

global path = "$projectpath/data\5_demand_elasticities"
cd $path
cap mkdir out
cap mkdir temp
global folder = "$path/out"

*******************************************************************************
** Aggregate pass-through regressions
*******************************************************************************


use "${path}\temp\data_y", replace

global controllist "dY dU dX dM" 

* prep-reg: get usesmpl
reghdfe dP_d dE $controllist, absorb(prod8#destin firm#prod8#ty) cluster(destin#ty)
gen usesmpl = e(sample)

* (1) baseline
reghdfe dP_d dE $controllist if preGFC == 1 & usesmpl, absorb(prod8#destin prod8#ty firm#ty) cluster(destin#ty) 
eststo_wrap, model("pt1")
distinct destin if e(sample)
estadd r(ndistinct)

* (2) exclude euro area countries
reghdfe dP_d dE $controllist if preGFC == 1 & fixE == 0 & usesmpl, absorb(prod8#destin prod8#ty firm#ty) cluster(destin#ty) 
eststo_wrap, model("pt2")
distinct destin if e(sample)
estadd r(ndistinct)

* (3) incl. post-GFC
reghdfe dP_d dE $controllist if usesmpl, absorb(prod8#destin prod8#ty firm#ty) cluster(destin#ty) 
eststo_wrap, model("pt3")
distinct destin if e(sample)
estadd r(ndistinct)

* (4) AIK benchmark light
reghdfe dP_d dE $controllist if preGFC & usesmpl, absorb(prod8#destin) cluster(destin#ty)
eststo_wrap, model("pt4")
distinct destin if e(sample)
estadd r(ndistinct)

* (5) AIK benchmark + firm-product-time FE
reghdfe dP_d dE $controllist if preGFC & usesmpl, absorb(prod8#destin firm#prod8#ty) cluster(destin#ty)
eststo_wrap, model("pt5")
distinct destin if e(sample)
estadd r(ndistinct)

esttab pt1 pt2 pt3 pt4 pt5, cells(b(fmt(3) star) se(fmt(3)par)) keep(dE) ///
	mtitles("Baseline" "excl. fix" "incl. postGFC" "No marg. cost control" "More marg. cost control") scalar(N Firms ndistinct)
	
esttab pt1 pt2 pt3 pt4 pt5 using $folder/TabC2_stratcompreg.tex, replace cells(b(fmt(3) star) se(fmt(3)par)) keep(dE) ///
	mtitles("Baseline" "excl. fix" "incl. postGFC" "No marg. cost control" "More marg. cost control") scalar(N Firms ndistinct)
	

*******************************************************************************
** Pass-through estimated for each CN2-category
*******************************************************************************

log using "${path}\out\ptreg_by_CN2.log", replace

use "${path}\temp\data_y", replace

reghdfe dP_d i.prod2#c.dE $controllist if preGFC == 1, absorb(prod8#destin prod8#ty firm#ty) vce(cl destin)

matrix B = e(b)'
svmat2 B, name(betaSC) r(cat)
matrix SE = vecdiag(e(V))'
svmat2 SE, name(seSC)
replace betaSC = . if cat == "_cons"
replace cat = substr(cat, 1, strpos(cat, ".")-1)
replace betaSC = . if strpos(cat, "o")>0
replace cat = subinstr(cat, "o", "", .)
replace cat = subinstr(cat, "b", "", .)
gen catnumCN2 = real(cat)
label val catnumCN2 prod2
keep catnumCN2 betaSC seSC
drop if catnumCN2 == .
decode catnumCN2, gen(cn2)  

save "${path}\out\betaSC_by_CN2", replace	

log close

