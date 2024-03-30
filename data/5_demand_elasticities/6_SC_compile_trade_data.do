/*

	6_SC_compile_trade_data:
	
	This file loads export unit values and prepares the data for exchange-
	rate pass-through regressions.
	
	DEPENDENCIES:
	
	Inputs:
	
	 - data/5_demand_elasticities/in/DestinationControls.csv

	 - data/5_demand_elasticities/temp/exchangerates_cy
	 
	 - data/4_unitvalues/out/exportdata_countries
	 
	Outputs:
	 
	 - data/5_demand_elasticities/temp/data_y
	   hs6 year sigmaBW sigmaBWHS
	   For each HS6 code that shows up in any of our price data, we have sigmaBW 
	   and sigmaBWHS

*/

global path = "$projectpath/data\5_demand_elasticities"
cd $path
cap mkdir out
cap mkdir temp
global folder = "$path/out"

* 1. Compile and prepare destination controls
* 2. Import UHDM_exports, xtset to prodid-destination country level
* 3. Merge exchange rates on it
* 4. Add annual destination controls
* 5. Prep data for regression: get phi and S

** 1. Destination controls
import delim "${path}\in\DestinationControls.csv", varn(1) numericc(3/6) clear
cap rename ïcountry country
gen year = real(substr(date, 7, 4))
gen month = real(substr(date, 4, 2))
gen td = mdy(month, 1, year)
format td %td
gen tq = qofd(td)
format tq %tq
drop date year month td
encode country, gen(c_tmp)
xtset c_tmp tq
gen ty = yofd(dofq(tq))
collapse (firstnm) c_tmp (sum) gdp exports imports (mean) unemployment, by(country ty)
xtset c_tmp ty
gen dY = 100*(log(gdp) - log(L.gdp))
gen dU = unemployment - L.unemployment
gen dX = 100*(log(exports) - log(L.exports))
gen dM = 100*(log(imports) - log(L.imports))
keep country ty d*Y d*U d*X d*M
save "${path}\temp\destination_controls_y", replace

** 2. Import UHDM_exports
use "${projectpath}\data\4_unitvalues\out\exportdata_countries", clear
merge m:1 country using "${tradepath}\country_labels"
drop if _merge == 2
drop _merge
tab country_str, sort

* very little country cleaning (those that matter)
replace country_str = "Belgien" if strpos(country_str, "og Luxembou") > 0
replace country_str = "Tjekkiet" if strpos(country_str, "Tjekkisk") > 0
replace country_str = "" if strpos(country_str, "Uoplyst") > 0
replace country_str = "Frankrig" if strpos(country_str, "og Monaco") > 0
replace country_str = "New Zealand" if strpos(country_str, "N.Zealand") > 0
drop if country_str == "" // tiny fraction

* id at firm-product-destination level
egen prodid = group(cvrnr CN8)
egen prodestid = group(prodid country)
rename year ty
xtset prodestid ty

** 3. Merge exchange rates
merge m:1 country_str ty using "${path}\temp\exchangerates_cy"
tab country_str if _merge == 2
* 769 not merged, all from micro countries that, in some years, have no trade => drop
drop if _merge == 2
drop _merge
drop if currency == "DKK"
tab currency, m sort
/* Currency on 90% of trade, most prominent:
	- EUR: 30%
	- NOK: 12%
	- SEK: 9%
	- GBP: 4%
	- PLN: 3%
	- USD: 3%
	- ISK: 3%
	- CHF: 3%
*/
drop if E == .

** 4. Add annual destination controls
merge m:1 country ty using "${path}\temp\destination_controls_y"
drop if _merge == 2
gen tmp = dU ~= .
tabstat tmp, by(country_engl)  // 99.6% available

** 5. Prep data for regression

* Calculate unit values in domestic and foreign
gen P_d = value / quant
gen P_f = P_d * E // E is the exchange rate index with increase = appreciation of DKK

* Changes of quantities, unit values
xtset prodestid ty
gen dP_d = log(P_d) - log(L.P_d)
gen dP_f = log(P_f) - log(L.P_f)
gen dQ = log(quant) - log(L.quant)
gen dE = log(E) - log(L.E)

* Winsorization at (-1, 1)
foreach v of varlist dP_f dP_d {
	replace `v' = -1 if `v' < -1
	replace `v' = 1 if `v' > 1 & `v'~= .
}

* granularity of product classifications
gen CN2 = substr(CN8, 1, 2)

* fixed effects
encode country_engl, gen(destin)
drop country* tmp*
encode cvrnr, gen(firm)
encode CN8, gen(prod8)
encode CN2, gen(prod2)
distinct destin firm prod*  

* last stuff
gen preGFC = ty <= 2007
replace dE = -dE // positive = depreciation (to be consistent with literature)
drop if dP_d == .

save "${path}\temp\data_y", replace
