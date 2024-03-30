/*

	1_GEN_SAMPLE_2007:
	
	This file generates the relevant sample and constant 2007 characteristics from the firm register.

	DEPENDENCIES:
	
	Inputs:
	
	- $cleandatapath/FIRM/out/firm_nyvar_2007 (all firms registered in 2007)
	  cvrnr year GF_AARSV GF_ANSATTE GF_OMS GF_BAGATEL GF_NACE_DB
	
	  Data only used to check if firm is surviving
	- $cleandatapath/FIRM/out/firm_nyvar_`y'
	  GF_BAGATEL GF_OMS GF_AARSV GF_ANSATTE 
	- $cleandatapath/FIKS/out/fiks_annual
	  SALG_IALT 
	- $projectpath/data/1_combine_irtevirk_urtevirk/out/firm_panel
	  connections loans_uv interest
	
	  Data only used to check if firm has prices 
    - $cleandatapath/PPI/out/quarterly/ppi_domestic
	  panid year
	- $cleandatapath/UHDM/out/UHDM_exports
	  cvrnr year value
	
	  Data of 2007 (constant) firms characteristics
	- $projectpath/data/3_sample/out/exposure
	  tt_uvall loans_uv07 loans_pb07 loans_st07 connections07 connections_loans07
	  connections_deposits07 deposits07 interest_deposits07
	- $cleandatapath/FIKS/out/fiks_annual.dta for 2007
	  SALG_IALT INDENLANDSK_SALG EKSPORT_IALT KOB_IALT GRP_NR
	- $cleandatapath/FIRE/out/fire for 2007
	  elul hlul rfep uvbt libe jkod besk lgag besk at past egul akg alg kgl lgl hens rudg tgt
	- $cleandatapath/FIRM/out/firm_nyvar_2007
	  GF_ANSATTE GF_AARSV JUR_FRA_DATO JUR_VIRK_FORM GF_OMS GF_EKSP GF_RFEP 
	  GF_EGUL GF_LGAG GF_AT JUR_BEL_KOM_KODE JUR_HOVED_BRA_DB07
	- $cleandatapath/IRTEVIRK/out/firm_cash_holding for 2007
	  ISTAA_BLB
	  	 
	Outputs:
	
	 - data/3_sample/sample.dta, firm-level, used in almost all analysis scripts 	
	 
	 - Tab A.1

*/

global path = "$projectpath/data/3_sample"
cd $path
cap mkdir out
cap mkdir temp


********************************************************************************
* start with all active manufacturing firms in 2007
********************************************************************************

use cvrnr year GF_AARSV GF_ANSATTE GF_OMS GF_BAGATEL GF_NACE_DB using $cleandatapath/FIRM/out/firm_nyvar_2007, clear

// keep only active firms 
keep if GF_AARSV>1 & GF_ANSATTE>1 & GF_OMS>1000 & GF_BAGATEL==0 & !mi(GF_OMS) & !mi(GF_AARSV) & !mi(GF_ANSATTE)
rename (GF_BAGATEL GF_OMS GF_AARSV GF_NACE_DB) (GF_BAGATEL07 GF_OMS07 GF_AARSV07 nace)
gen nace2d = real(substr(nace, 1, 2))
cap destring nace*, replace
// keep only manufacturing firms
keep if inrange(nace2d, 10, 33)


********************************************************************************
* check if firm survives (firm has employees, revenues and a bank connection in all years)
********************************************************************************

cap gen year = .
forval y = 2005/2016 {
	di "`y'"
	merge 1:1 cvrnr using $cleandatapath/FIRM/out/firm_nyvar_`y', keep(match master) keepusing(GF_BAGATEL GF_OMS GF_AARSV GF_ANSATTE) nogen
	cap destring GF_BAGATEL, replace
	replace year = `y'
	merge 1:1 year cvrnr using $cleandatapath/FIKS/out/fiks_annual, keep(match master) keepusing(SALG_IALT) nogen
	merge 1:1 year cvrnr using $projectpath/data/1_combine_irtevirk_urtevirk/out/firm_panel, keep(match master) keepusing(connections loans_uv interest) nogen
	gen in`y' = GF_AARSV>1 & GF_ANSATTE>1 & GF_OMS>1000 & SALG_IALT>1000 & GF_BAGATEL==0 & !mi(GF_OMS) & !mi(GF_AARSV) & !mi(SALG_IALT) & !mi(GF_ANSATTE) & connections>0 & !mi(connections)
	gen loans_uv`y' = loans_uv
	gen interest`y' = interest
	drop GF_BAGATEL GF_OMS GF_AARSV SALG_IALT GF_ANSATTE connections loans_uv interest
}
replace year = 2007

* store loans / interest payments in wide format for later
gen loans_uv05 = loans_uv2005
gen loans_uv06 = loans_uv2006
gen loans_uv07 = loans_uv2007
drop loans_uv20*
gen interest05 = interest2005
gen interest06 = interest2006
gen interest07 = interest2007
drop interest20*
gen interest_rate07 = interest07/(0.5*(loans_uv06+loans_uv07))


********************************************************************************
* check if firms contained in price data (inUHDM/inPPI)
********************************************************************************

* PPI

preserve
use $cleandatapath/PPI/out/quarterly/ppi_domestic, clear
gegen has_2007 = max(year==2007), by(panid)
gegen has_2008 = max(year==2008), by(panid)
gegen has_2009 = max(year==2009), by(panid)
gegen has_2010 = max(year==2010), by(panid)
gen persistent_product = has_2007 & has_2008 & has_2009 & has_2010
gegen has_persistent_product = max(persistent_product), by(cvrnr)

keep cvrnr year has_persistent_product
duplicates drop

gen inPPI_ = 1
reshape wide inPPI_, i(cvrnr) j(year)

save $path/temp/inPPI, replace
restore

merge m:1 cvrnr using $path/temp/inPPI, keep(match master) nogen

* UHDM

cap drop inUHDM*
preserve
use $cleandatapath/UHDM/out/UHDM_exports, clear
gcollapse (sum) value, by(cvrnr year)
gen inUHDM_ = value>200000
drop value
reshape wide inUHDM_, i(cvrnr) j(year)
save $path/temp/inUHDM, replace
restore

merge m:1 cvrnr using $path/temp/inUHDM, keep(match master) nogen

foreach var of varlist inUHDM* inPPI* {
	replace `var' = 0 if mi(`var')
}
gen inPPI = inPPI_2007 & has_persistent_product
gen inUHDM = inUHDM_2007


********************************************************************************
* merge 2007 sample characteristics
********************************************************************************

* exposure
merge 1:1 cvrnr using $projectpath/data/3_sample/out/exposure, keep(match master) gen(_merge_exposure) keepus(tt_uvall loans_uv07 loans07 loans_pb07 loans_st07 connections07 connections_loans07 connections_deposits07 deposits07 interest_deposits07)

* fiks
merge 1:1 cvrnr year using $cleandatapath/FIKS/out/fiks_annual.dta, gen(_FIKS_merge) keep(match master) keepusing(SALG_IALT INDENLANDSK_SALG EKSPORT_IALT KOB_IALT GRP_NR)

rename (SALG_IALT INDENLANDSK_SALG EKSPORT_IALT KOB_IALT) (revenue_fiks07 domestic_fiks07 export_fiks07 purchases_fiks07)

* fire
merge 1:1 cvrnr year using $cleandatapath/FIRE/out/fire, gen(_FIRE_merge) keep(match master) keepusing(elul hlul rfep uvbt libe jkod besk lgag besk at past egul akg alg kgl lgl hens rudg tgt)

rename elul elul07
rename hlul hlul07
rename uvbt uvbt07
rename rfep rfep07
rename libe libe07
rename besk besk07
rename lgag lgag07
rename at at07
rename past past07
rename egul egul07
rename jkod jkod07
rename akg akg07
rename alg alg07
rename kgl kgl07
rename lgl lgl07
rename hens hens07
rename rudg rudg07

* firm
merge m:1 cvrnr using $cleandatapath/FIRM/out/firm_nyvar_2007, gen(_FIRM_merge) keep(match master) keepusing(GF_ANSATTE GF_AARSV JUR_FRA_DATO JUR_VIRK_FORM GF_OMS GF_EKSP GF_RFEP GF_EGUL GF_LGAG GF_AT JUR_BEL_KOM_KODE JUR_HOVED_BRA_DB07)

gen nace_grp = .
replace nace_grp = 1 if inrange(nace2d,10,12)
replace nace_grp = 2 if inrange(nace2d,13,15)
replace nace_grp = 3 if inrange(nace2d,16,18)
replace nace_grp = 4 if nace2d==19
replace nace_grp = 5 if nace2d==20
replace nace_grp = 6 if nace2d==21
replace nace_grp = 7 if inrange(nace2d,22,23)
replace nace_grp = 8 if inrange(nace2d,24,25)
replace nace_grp = 9 if nace2d==26
replace nace_grp = 10 if nace2d==27
replace nace_grp = 11 if nace2d==28
replace nace_grp = 12 if inrange(nace2d,29,30)
replace nace_grp = 13 if inrange(nace2d,31,33)
replace nace_grp = 14 if inrange(nace2d,45,47)

label def grps 1 "Food, beverages, tobacco" 2 "Textiles, apparel, leather" 3 "Wood, paper, printing" 4 "Coke and petroleum" 5 "Chemicals" 6 "Pharma" 7 "Plastics" 8 "Metal" 9 "Electronics" 10 "Electrical equipment" 11 "Machinery" 12 "Transport equipment" 13 "Other" 14 "Wholesale", replace
label values nace_grp grps

foreach var in GF_OMS GF_EKSP GF_RFEP GF_EGUL GF_LGAG GF_AT {
	replace `var' = `var'/1000
}

rename GF_ANSATTE emp07
rename GF_AARSV fte07
rename JUR_VIRK_FORM legaltype
rename GF_LGAG lgag_firm07
rename GF_OMS revenue07
rename GF_EKSP export_firm07
rename GF_RFEP profit_firm07
rename GF_EGUL equity_firm07
rename GF_AT assets_firm07

* IRTEVIRK
merge m:1 cvrnr year using $cleandatapath/IRTEVIRK/out/firm_cash_holdings, gen(_IRTEVIRK_merge) keep(match master) keepusing(ISTAA_BLB)

rename ISTAA_BLB cash_deposits07
replace cash_deposits07 = 0 if cash_deposits07 == .
replace cash_deposits07 = cash_deposits07 / 1000


********************************************************************************
* auxiliary variables variables
********************************************************************************

gen pbshare07 = loans_pb07 / loans_uv07
gen stshare07 = loans_st07 / loans_uv07
gen exp_share07 = export_fiks07 / revenue_fiks07
gegen totalrevenue_4d = total(revenue07), by(nace)
gen ms_4d07 = revenue07 / totalrevenue_4d
drop totalrevenue_4d
gen firmage04 = (dofm(ym(2007,12)) - JUR_FRA_DATO) / 365.25
gen deposits_to_revenue07 = cash_deposits07 / revenue07
gen profit_to_revenue07 = profit_firm07 / revenue07
gen inv_to_revenue07 = uvbt07 / revenue07 
gen work_capital07 = uvbt07 + tgt - lgl - kgl
drop tgt lgl kgl
gen wk_to_revenue07 = work_capital07 / revenue07
gen avg_wage07 = lgag_firm07 / fte07
gen equity_share07 = equity_firm07 / assets_firm07
gen loans_share07 = loans07 / assets_firm07 
gen loans_to_revenue07 = loans07 / revenue07
gen deposits_to_lgag07 = cash_deposits07 / lgag_firm07
winsor2 loans_share07 avg_wage07 inv_to_revenue07 loans_to_revenue07 deposits_to_revenue07, replace cut(0 99)
winsor2 profit_to_revenue07 equity_share07, replace cut(1 99)

gen lemp07 = log(emp07)
gen lrevenue07 = log(revenue07)
gen size = .
replace size = 1 if emp07<50
replace size = 2 if inrange(emp07,50, 249)
replace size = 3 if emp07>=250 & emp07<.

* private sector companies excluding finance, government, real estate and construction
gen business = inlist(legaltype, 80, 60, 90, 81, 280, 100, 130, 210, 150, 140, 40, 170, 180, 30, 285, 270, 15, 20, 70, 290, 190, 160)
gen npo = inlist(legaltype, 110, 115, 260, 151, 152)
gen government = inlist(legaltype, 230, 250) | nace2d == 84 | nace2d == 99 | nace2d == 85
gen finance = inrange(nace2d, 64, 66)

save $path/temp/temp_sample, replace


********************************************************************************
* SAMPLE CONDITIONS AND SELECTION TABLE (Tab A.1)
********************************************************************************

use $path/temp/temp_sample, replace

** test bite of each restriction
global manu = "inrange(nace2d,10,33)"
global sizereq = `"emp07>10 & GF_AARSV>10 & GF_OMS07>1000000 & !mi(GF_OMS07) & !mi(emp07) & !mi(revenue07) & !mi(GF_AARSV) & GF_BAGATEL==0 & jkod07!="R""'
global loansreq = "loans_uv07>100 & loans_uv06>100 & loans_to_revenue07>0.01"
global privatesector = "business & !finance & !government"
global uvmerge = "((loans_uv07>0 & !mi(loans_uv07)) | (deposits07>0 & !mi(deposits07)) | (interest07>0 & !mi(interest07)) | (interest_deposits07>0 & !mi(interest_deposits07)))"
global survival = "in2005 & in2006 & in2007 & in2008 & in2009 & in2010" 

preserve

gen restr_all_1ind = $manu & $privatesector
gen restr_all_2size = $sizereq & restr_all_1ind
gen restr_all_3uv = $uvmerge & restr_all_2size
gen restr_all_4survival = $survival & restr_all_3uv
gen restr_all_5loansreq = $loansreq & restr_all_4survival

gen restr_ppi_1ind = restr_all_1ind * inPPI
gen restr_ppi_2size = restr_all_2size * inPPI
gen restr_ppi_3uv = restr_all_3uv * inPPI
gen restr_ppi_4survival = restr_all_4survival * inPPI
gen restr_ppi_5loansreq = restr_all_5loansreq * inPPI

gen restr_uhdm_1ind = restr_all_1ind * inUHDM
gen restr_uhdm_2size = restr_all_2size * inUHDM
gen restr_uhdm_3uv = restr_all_3uv * inUHDM
gen restr_uhdm_4survival = restr_all_4survival * inUHDM
gen restr_uhdm_5loansreq = restr_all_5loansreq * inUHDM

gen emp_all_1ind = emp07 * restr_all_1ind
gen emp_all_2size = emp07 * restr_all_2size
gen emp_all_3uv = emp07 * restr_all_3uv
gen emp_all_4survival = emp07 * restr_all_4survival
gen emp_all_5loansreq = emp07 * restr_all_5loansreq

gen emp_ppi_1ind = emp07 * restr_ppi_1ind
gen emp_ppi_2size = emp07 * restr_ppi_2size
gen emp_ppi_3uv = emp07 * restr_ppi_3uv
gen emp_ppi_4survival = emp07 * restr_ppi_4survival
gen emp_ppi_5loansreq = emp07 * restr_ppi_5loansreq

gen emp_uhdm_1ind = emp07 * restr_uhdm_1ind
gen emp_uhdm_2size = emp07 * restr_uhdm_2size
gen emp_uhdm_3uv = emp07 * restr_uhdm_3uv
gen emp_uhdm_4survival = emp07 * restr_uhdm_4survival
gen emp_uhdm_5loansreq = emp07 * restr_uhdm_5loansreq

gcollapse (sum) restr_all* restr_ppi* restr_uhdm* emp_all* emp_ppi* emp_uhdm* 
sum emp_all_1ind emp_all_5loansreq emp_ppi_5loansreq emp_uhdm_5loansreq //emp_all_1ind = 366541

gen i = 1
reshape long restr_all restr_ppi restr_uhdm emp_all emp_ppi emp_uhdm, i(i) j(name) string
replace emp_ppi = emp_ppi / emp_all
replace emp_uhdm = emp_uhdm / emp_all
sum emp_all if name == "_1ind"
loc totalemp = r(mean)
replace emp_all = emp_all / `totalemp'
sort name

drop i
order name restr_all emp_all restr_ppi emp_ppi restr_uhdm emp_uhdm

dataout, tex replace save($path/out/TabA1_selection.tex) auto(2)

restore

* do the actual dropping and save
keep if $manu
keep if $sizereq
keep if $privatesector
keep if $uvmerge
keep if $survival

compress
save $path/out/sample, replace


********************************************************************************
*  just for reference: total privat sector employment
********************************************************************************

use $cleandatapath/FIRM/out/firm_nyvar_2007, replace
keep if GF_AARSV>1 & GF_ANSATTE>1 & GF_OMS>1000 & GF_BAGATEL==0 & !mi(GF_OMS) & !mi(GF_AARSV) & !mi(GF_ANSATTE)
rename (GF_BAGATEL GF_OMS GF_AARSV GF_ANSATTE JUR_VIRK_FORM GF_NACE_DB) (GF_BAGATEL07 GF_OMS07 GF_AARSV07 emp07 legaltype nace)
gen nace2d = real(substr(nace, 1, 2))
gen business = inlist(legaltype, 80, 60, 90, 81, 280, 100, 130, 210, 150, 140, 40, 170, 180, 30, 285, 270, 15, 20, 70, 290, 190, 160)
gen npo = inlist(legaltype, 110, 115, 260, 151, 152)
gen government = inlist(legaltype, 230, 250) | nace2d == 84 | nace2d == 99 | nace2d == 85
gen finance = inrange(nace2d, 64, 66)
keep if $privatesector
gen cumemp07 = sum(emp07)
list cumemp07 if _n==_N  // 1.518.272 -- private-sector employment in DK
