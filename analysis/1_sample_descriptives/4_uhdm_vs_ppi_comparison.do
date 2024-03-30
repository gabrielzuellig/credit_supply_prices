global path = "$projectpath/analysis/1_sample_descriptives"

cd $path
cap mkdir out
cap mkdir temp

global euroarea = `"(inlist(country, "AT", "BE", "CY", "EE", "FI", "FR", "DE", "GR", "IE") | inlist(country, "IT", "LT", "LU", "MT", "NL", "PT", "SK", "SI", "ES") | inlist(country,"LV", "FO", "GL"))"'
global noneuroeea = `"(inlist(country, "GB","BG", "HR", "CZ", "HU", "PL", "RO") | inlist(country, "SE", "NO", "CH", "IS"))"'
global northamerica = `"inlist(country, "US", "CA", "JP", "AU", "NZ")"'


cap program drop gen_unitvalues_yearly
program def gen_unitvalues_yearly
	********************************************************************************
	* unit values
	********************************************************************************
	drop if quant == 0
	drop if value == 0
	cap drop uv1
	cap drop uv2
	gen uv1 = value / quant
	gen uv2 = value / weight
	
	* uv1 adj 
	cap drop missing
	gen missing = uv1 == .
	bys cvrnr panid missing (year): gen Dp = log(uv1 / uv1[_n-1])
	replace Dp = -1 if Dp < -1 & !missing(Dp)
	replace Dp = 1 if Dp > 1 & !missing(Dp)
	bys cvrnr panid missing (year): gen ladj = sum(Dp)
	bys cvrnr panid missing (year): gen uv1adj = exp(ladj) * uv1[1]
	replace uv1adj = . if uv1 ==.
	drop Dp ladj missing

	* uv2 adj
	cap drop missing
	gen missing = uv2 == .
	bys cvrnr panid missing (year): gen Dp = log(uv2 / uv2[_n-1])
	replace Dp = -1 if Dp < -1 & !missing(Dp)
	replace Dp = 1 if Dp > 1 & !missing(Dp)
	bys cvrnr panid missing (year): gen ladj = sum(Dp)
	bys cvrnr panid missing (year): gen uv2adj = exp(ladj) * uv2[1]
	replace uv2adj = . if uv2 ==.
	drop Dp ladj missing

	order cvrnr panid uv1 uv2 uv1adj uv2adj value quant weight
	sort cvrnr panid year

	gen luv1adj = log(uv1adj)
	gen luv2adj = log(uv2adj)

	*gen year = year(dofq(tq))

	gegen lprice_sd = sd(luv1adj), by(cvrnr panid)
	gegen lprice_sd2 = sd(luv1adj) if inrange(year,2000,2007), by(cvrnr panid)
	gen varw = 1/lprice_sd^2
	gen varw2 = 1/lprice_sd2^2
	bys cvrnr panid (varw2): replace varw2 = varw2[1]

	keep if inrange(year,2005,2010)
end


********************************************************************************
********************************************************************************
* Generate _quarterly_ unit value indices for ppi vs unit value comparison
********************************************************************************
********************************************************************************

use "E:\ProjektDB\706172\Rawdata\707904\CLEANDATA\UHDM/out/UHDM_exports.dta", clear
gen tq = yq(year(dofm(tm)), quarter(dofm(tm)))
keep if $euroarea | $noneuroeea


gcollapse (sum) value quant weight, by(cvrnr CN8 prodid tq) fast
gegen panid = group(prodid cvrnr)
xtset panid tq

********************************************************************************
* unit values
********************************************************************************
drop if quant == 0
drop if value == 0
gen uv1 = value / quant
gen uv2 = value / weight

* uv1 adj 
gen missing = uv1 == .
bys cvrnr panid missing (tq): gen Dp = log(uv1 / uv1[_n-1])
replace Dp = -1 if Dp < -1 & !missing(Dp)
replace Dp = 1 if Dp > 1 & !missing(Dp)
bys cvrnr panid missing (tq): gen ladj = sum(Dp)
bys cvrnr panid missing (tq): gen uv1adj = exp(ladj) * uv1[1]
replace uv1adj = . if uv1 ==.
drop Dp ladj missing

* uv2 adj
gen missing = uv2 == .
bys cvrnr panid missing (tq): gen Dp = log(uv2 / uv2[_n-1])
replace Dp = -1 if Dp < -1 & !missing(Dp)
replace Dp = 1 if Dp > 1 & !missing(Dp)
bys cvrnr panid missing (tq): gen ladj = sum(Dp)
bys cvrnr panid missing (tq): gen uv2adj = exp(ladj) * uv2[1]
replace uv2adj = . if uv2 ==.
drop Dp ladj missing

order cvrnr panid tq uv1 uv2 uv1adj uv2adj value quant weight
sort cvrnr panid tq

gen luv1adj = log(uv1adj)
gen luv2adj = log(uv2adj)

gen year = year(dofq(tq))

gegen lprice_sd = sd(luv1adj), by(cvrnr panid)
gegen lprice_sd2 = sd(luv1adj) if inrange(year,2000,2007), by(cvrnr panid)
gen varw = 1/lprice_sd^2
gen varw2 = 1/lprice_sd2^2
bys cvrnr panid (varw2): replace varw2 = varw2[1]

* merge constants from firm sample 
merge m:1 cvrnr using $projectpath/data/3_sample/out/sample.dta, keep(match) nogen keepusing(cvrnr)

********************************************************************************
* Product level sample restrictions
********************************************************************************

gegen meanvalue = mean(value), by(panid)
drop if value < 1000
drop if meanvalue < 10000

* drop short/spotty PRODUCTS (not series): less than 8 obs, or less than 50% coverage over panel series
*gegen obs = count(value), by(panid)
*gegen prodstart = min(tq), by(panid)
*gegen prodend = max(tq), by(panid)
*gen coverage = obs / (prodend - prodstart + 1)
*drop if obs < 16 | coverage < 0.5

save $path/temp/unitvalues_eu_quarterly, replace

********************************************************************************
* Comparison graph
********************************************************************************

use $path/temp/unitvalues_eu_quarterly, clear

gen CN6 = real(substr(CN8,1,6))
gen CN4 = real(substr(CN8,1,4))
gen CN2 = real(substr(CN8,1,2))

merge m:1 cvrnr using $projectpath/data/3_sample/out/sample.dta, keep(match) nogen
keep if inPPI

xtset panid tq
gen Dp_uhdm = log(uv2adj / L.uv2adj)
gegen temp = total(value), by(cvrnr CN8 year)
gen valweight = L4.temp
keep if meanvalue>10000
gcollapse (mean) Dp_uhdm [weight=valweight], by(cvrnr tq CN4)
destring cvrnr, replace
save $path/temp/temp, replace

use "$projectpath/analysis/3_did_ppi/temp/panel", clear
xtset panid tq
cap drop CN4
gen CN4 = real(substr(hs,1,4))
gen Dp_ppi = log(prisadj2 / L.prisadj2)
gcollapse (mean) Dp_ppi (firstnm) nace, by(cvrnr tq CN4)

merge 1:1 cvrnr CN4 tq using $path/temp/temp
gegen sd = sd(Dp_uhdm), by(cvrnr)
gen varw = 1/sd^2

cap drop panid
gegen panid = group(cvrnr CN4)

xtset panid tq
cap drop error
cap drop sde
cap drop w

reghdfe Dp_uhdm L(0/5).Dp_ppi F(1/5).Dp_ppi if tq>yq(2005,1) & tq<=yq(2010,4), absorb(panid tq) resid(error)
gegen sde = sd(error), by(panid)
gen w = 1/sde^2
reghdfe Dp_uhdm L(0/5).Dp_ppi F(1/5).Dp_ppi [aweight=w] if tq>yq(2005,1) & tq<=yq(2010,4), absorb(panid tq)
est sto firmw
reghdfe Dp_uhdm L(0/5).Dp_ppi F(1/5).Dp_ppi  if tq>yq(2005,1) & tq<=yq(2010,4), absorb(panid tq)
est sto now

coefplot (now, label("No weights") offset(-0.1)) (firmw, label("Two-step estimation with 1/var(resid) weights") offset(0)), keep(L5.Dp_ppi L4.Dp_ppi L3.Dp_ppi L2.Dp_ppi  L.Dp_ppi Dp_ppi F.Dp_ppi  F2.Dp_ppi  F3.Dp_ppi  F4.Dp_ppi  F5.Dp_ppi) order(L5.Dp_ppi L4.Dp_ppi L3.Dp_ppi L2.Dp_ppi L.Dp_ppi Dp_ppi F.Dp_ppi  F2.Dp_ppi  F3.Dp_ppi  F4.Dp_ppi  F5.Dp_ppi) coeflabel(L5.Dp_ppi=-5 L4.Dp_ppi=-4 L3.Dp_ppi=-3 L2.Dp_ppi=-2 L.Dp_ppi=-1 Dp_ppi=0 F.Dp_ppi=+1  F2.Dp_ppi=+2  F3.Dp_ppi=+3  F4.Dp_ppi=+4  F5.Dp_ppi=+5, alternate) yline(0, lcolor(gs9)) vertical recast(connected) ciopt(recast(rcap)) omitted baselevels levels(95) ytitle("Correlation between PPI and UV inflation at HS4 lvl") xtitle("Quarters")
graph export $path/out/FigB1_uhdm_vs_ppi.pdf, as(pdf) replace

est restore firmw
lincom L.Dp_ppi+Dp_ppi+F.Dp_ppi+F2.Dp_ppi