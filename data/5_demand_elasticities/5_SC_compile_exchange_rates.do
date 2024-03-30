/*

	5_SC_compile_exchange_rates:
	
	This file prepares exchange rates for pass-through regressions.
	
	DEPENDENCIES:
	
	Inputs:
	
	 - data/5_demand_elasticities/in/exchange_rates_9506.txt
 	 - data/5_demand_elasticities/in/exchange_rates_0717.txt
	 - data/5_demand_elasticities/in/country_currency_keys.txt
	 
	Outputs:
	 
	 - data/5_demand_elasticities/temp\exchangerates_cm

*/

global path = "$projectpath/data\5_demand_elasticities"
cd $path
cap mkdir out
cap mkdir temp
global folder = "$path/out"

** 1. Import from statistikbanken
import delim "${path}\in\exchange_rates_0717.txt", varn(1) clear
save "${path}\temp\exchange_rates_0717", replace
import delim "${path}\in\exchange_rates_9506.txt", varn(1) clear
append using "${path}\temp\exchange_rates_0717"

** 2. Clean variables
drop kurstype v5
rename månedsgennemsnit exchangeRate

gen tm = monthly(tid, "YM")
format tm %tm
drop tid

replace exchangeRate = "" if exchangeRate == ".."
destring exchangeRate, replace

gen tmp = valuta
replace valuta = substr(valuta, 1, strpos(valuta, "(")-2)
tab valuta, m // 57; the missing one is "all others" (not needed)
/* "old" euro area currencies have values up to 2002m12, but they follow the 
same growth rates as the euro */
replace valuta = "USD" if strpos(valuta, "Amerikansk") > 0
replace valuta = "" if strpos(valuta, "Anden") > 0 // not relevant
replace valuta = "AUD" if strpos(valuta, "Austral") > 0
replace valuta = "BEF" if strpos(valuta, "Belg") > 0
replace valuta = "BRL" if strpos(valuta, "Brasil") > 0
replace valuta = "GBP" if strpos(valuta, "Britisk") > 0
replace valuta = "BGN" if strpos(valuta, "Bulgar") > 0
replace valuta = "CAD" if strpos(valuta, "Canad") > 0
replace valuta = "CYP" if strpos(valuta, "Cypriot") > 0
replace valuta = "EUR" if strpos(valuta, "Ecu") > 0 & tm <= ym(1998,12) // drop after 99
replace valuta = "" if strpos(valuta, "Ecu") > 0 & tm >= ym(1999,1)
replace valuta = "EEK" if strpos(valuta, "Esti") > 0
replace valuta = "EUR" if strpos(valuta, "Euro") > 0 & tm >= ym(1999,1)
replace valuta = "" if strpos(valuta, "Euro") > 0 & tm <= ym(1998,12)
replace valuta = "PHP" if strpos(valuta, "Filippin") > 0
replace valuta = "FIM" if strpos(valuta, "Finsk") > 0
replace valuta = "FRF" if strpos(valuta, "Fransk") > 0
replace valuta = "" if strpos(valuta, "tyrk") > 0 // too small to say anything about Turkey before currency reform (1 Jan 2005)
replace valuta = "GRD" if strpos(valuta, "drachma") > 0
replace valuta = "HKD" if strpos(valuta, "Hongkong") > 0
replace valuta = "INR" if strpos(valuta, "rupie") > 0
replace valuta = "IDR" if strpos(valuta, "Indones") > 0
replace valuta = "IEP" if strpos(valuta, "Irsk") > 0
replace valuta = "ISK" if strpos(valuta, "Island") > 0
replace valuta = "ILS" if strpos(valuta, "Israel") > 0
replace valuta = "ITL" if strpos(valuta, "Italien") > 0
replace valuta = "JPY" if strpos(valuta, "Japan") > 0
replace valuta = "CNY" if strpos(valuta, "yuan") > 0
replace valuta = "HRK" if strpos(valuta, "Kroat") > 0
replace valuta = "LVL" if strpos(valuta, "Letti") > 0
replace valuta = "LTL" if strpos(valuta, "Litau") > 0
replace valuta = "MYR" if strpos(valuta, "Malaysi") > 0
replace valuta = "MTL" if strpos(valuta, "Maltes") > 0
replace valuta = "MXN" if strpos(valuta, "Mexikan") > 0
replace valuta = "NLG" if strpos(valuta, "Nederland") > 0
replace valuta = "NZD" if strpos(valuta, "New Zealand") > 0
replace valuta = "" if strpos(valuta, "effektiv") > 0  // weighted, not relevant
replace valuta = "NOK" if strpos(valuta, "Norsk") > 0
replace valuta = "PLN" if strpos(valuta, "zloty") > 0
replace valuta = "PTE" if strpos(valuta, "Portug") > 0
replace valuta = "" if strpos(valuta, "Rumæn") > 0 & tm <= ym(2005,6)
replace valuta = "" if strpos(valuta, "Gl. rumæn") > 0 & tm >= ym(2005,7)
replace valuta = "RON" if strpos(valuta, "Rumæn") > 0 | strpos(valuta, "rumæn") > 0
replace exchangeRate = exchangeRate*10^4 if valuta == "RON" & tm <= ym(2005,6) // currency reform 1 July 2005
replace valuta = "RUB" if strpos(valuta, "Russis") > 0
replace valuta = "" if strpos(valuta, "SDR") > 0 // special drawing rights, not relevant
replace valuta = "CHF" if strpos(valuta, "Schweiz") > 0
replace valuta = "SGD" if strpos(valuta, "Singapore") > 0
replace valuta = "SKK" if strpos(valuta, "Slovak") > 0
replace valuta = "SIT" if strpos(valuta, "Sloven") > 0
replace valuta = "ESP" if strpos(valuta, "Spansk") > 0
replace valuta = "SEK" if strpos(valuta, "Svensk") > 0
replace valuta = "ZAR" if strpos(valuta, "Sydafrikan") > 0
replace valuta = "KRW" if strpos(valuta, "Sydkorea") > 0
replace valuta = "THB" if strpos(valuta, "Thailand") > 0
replace valuta = "CZK" if strpos(valuta, "Tjekk") > 0
replace valuta = "TRY" if strpos(valuta, "Tyrk") > 0
replace valuta = "DEM" if strpos(valuta, "Tysk") > 0
replace valuta = "HUF" if strpos(valuta, "Ungar") > 0
replace valuta = "ATS" if strpos(valuta, "schilling") > 0
drop if valuta == ""

rename valuta currency
sort currency tm
tab currency if exchangeRate ~= .

save "${path}\temp\exchange_rates_complete", replace




** 3. Links between countries and currencies
* import
import delim "${path}\in\country_currency_keys.txt", varn(1) clear

* clean countries
drop v6
replace country_engl = country_str if country_engl == ""
replace country_str = country_str[_n-1] if country_str == ""
replace country_engl = country_engl[_n-1] if country_engl == ""
gen tmp = country_str ~= country_str[_n-1]
gen c = sum(tmp)

* semi-fixed exchange rate dummy
cap drop tmp
gen tmp = 1 if inlist(currency, "EUR")
bys c: egen fixE = mean(tmp)
replace fixE = 0 if fixE ~= 1
tab fixE

* time
gen m1 = monthly(start, "YM")
replace m1 = ym(1995,1) if m1 == .
gen m2 = monthly(end, "YM")
replace m2 = ym(2017,12) if m2 ==.
gen dur = m2 - m1 + 1
gen rebase_EA = currency[_n] ~= "EUR" & currency[_n+1] == "EUR"
replace dur = dur + 1 if rebase_EA == 1 // need one period of overlap
expand dur
sort c m1
bys c currency: gen m3 = _n-1
bys c currency: gen tm = m1 + _n-1
format tm %tm
* flag last observation before going into euro: 1. last obs. of country-currency spell, 2. next obs is euro
bys c currency (tm): gen last_of_spell = _n == _N
bys c (tm): gen switch_to_eur = currency[_n] ~= "EUR" & currency[_n+1] == "EUR"
cap drop rebase_point
gen rebase_point = last_of_spell == 1 & switch_to_eur == 1
replace currency = "EUR" if rebase_point == 1
replace tm = tm - 1 if rebase_point == 1
drop start end tmp m1-m3 last_of_spell switch_to_eur

** 4. merge with exchange rate file
merge m:1 currency tm using "${path}\temp\exchange_rates_complete"
/* using only: exchange rate but no country-currency pair, true for:
	- euro area countries' national currencies after 1999
	- EUR before 99 ==> DROP
   master only: no exchange rate information, true for:
    - "unimportant" countries, and some trading partners before 00's
*/
drop if _merge == 2
drop _merge
gsort c tm rebase_point

/* 5. build currency index: 
  - divide by 100
 - link national currencies that go into Eurozone at the first obs. of the euro
 - set equal to 1 in 2010m1
 - take inverse (s.t. positive change = appreciation)
*/
gen E = exchangeRate / 100

cap drop tmp
gen tmp = E / E[_n-1] if rebase_point == 1
replace currency = currency[_n-1] if rebase_point == 1
bys c currency (tm): egen rebase_factor = mean(tmp)
replace E = E*rebase_factor if rebase_factor ~= . 
drop if rebase_point == 1
drop rebase* 

cap drop tmp
gen tmp = E if tm == ym(2010,1)
bys c (tm): egen base = mean(tmp)
gen E2 = E / base
drop base

drop E 
gen E = 1 / E2
drop tmp E2

** 6. aggregate to annual frequency
gen ty = yofd(dofm(tm))
collapse (firstnm) country_engl currency c fixE (mean) exchangeRate E, by(country_str ty)

save "${path}\temp\exchangerates_cy", replace

