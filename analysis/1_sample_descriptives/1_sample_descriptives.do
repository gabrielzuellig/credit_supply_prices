/*

	1_GEN_PPI_PANEL:
	
	This file generates figures and tables with descriptive statistics for 
	different samples (e.g. all firms, firms with prices, firms with prices
	linked to wholesale-funded banks)

	DEPENDENCIES:
	
	Inputs:
	- $projectpath/data/3_sample/out/panel.dta
	
	- $cleandatapath/PPI/out/quarterly/ppi_domestic.dta
	  Dp2

	- $projectpath/analysis/4_did_uhdm/temp/panel.dta
	  Duv1

	- $projectpath/data/5_demand_elasticities/temp/firmlvl_DE_PPIfirms
	  sigmaBW_PPI
	
	- $projectpath/data/5_demand_elasticities/temp/firmlvl_DE_UHDMfirms
	  sigmaBW_UHDM

	Outputs:
	 - Fig A.1a-b, A.3-A.5
	 - Tab 1, A.2

*/


global path = "$projectpath/analysis/1_sample_descriptives"
cd $path

global folder = "$path/out"

cap mkdir $path/out
cap mkdir $path/temp
cap mkdir $folder

********************************************************************************
* programs
********************************************************************************

cap program drop percentile_plot_tt
program percentile_plot_tt
	syntax varlist(min=1 max=1) [if] [, noindu(string) printKS(string) deciles(string) *]
	
	cap drop insample_plot
	cap drop xb
	
	if "`deciles'" == "" {
		loc deciles = "10,20,30,40,50,60,70,80,90"
	}
	
	gen insample_plot = 1 `if'
	replace insample_plot = 0 if insample!=1
	
	disp "`noindu'"
	if "`noindu'" == ""{
		areg `varlist' `if', a(nace)
		predict xb, xbd
		replace xb = `varlist' - xb + _b[_cons]
		_crcslbl xb `varlist'
	}
	else {
		gen xb = `varlist'
	}
	
	ksmirnov xb `if', by(KScat1)
	local KSpval1 = r(p)
	local KSpval1 : di %4.2f `KSpval1' 
	ksmirnov xb `if', by(KScat2)
	local KSpval2 = r(p)
	local KSpval2 : di %4.2f `KSpval2'

	bys cond insample (xb): gen ptile = (int(10*(_n-1)/_N)+1) * 10
	tab ptile cond if !mi(xb)
	bys cond insample  ptile (xb): gen plot = _n==_N & inlist(ptile,`deciles') & insample_plot
	if "`printKS'" == ""{
		twoway (connected ptile xb if plot & cond==1, msize(vsmall) color(blue) lpattern(solid)) ///
			(connected ptile xb if plot & cond==2, msize(vsmall) color(red) lpattern(solid)) ///
			(connected ptile xb if plot & cond==3, msize(vsmall) color(blue) lpattern(dash)) ///
			(connected ptile xb if plot & cond==4, msize(vsmall) color(red) lpattern(dash)), ///
			ytitle("Percentile of firms") ylabel(0(10)90, grid) ///
			legend(label(1 "No exposure") label(2 "Full exposure") label(3 "Exposure in (0.02,0.5]") label(4 "Exposure in (0.5,0.98)") rows(2)) `options'
	}
	else {
		sum xb if plot 
		local upperlim = r(max)
		twoway (connected ptile xb if plot & cond==1, msize(vsmall) color(blue) lpattern(solid)) ///
		(connected ptile xb if plot & cond==2, msize(vsmall) color(red) lpattern(solid)) ///
		(connected ptile xb if plot & cond==3, msize(vsmall) color(blue) lpattern(dash)) ///
		(connected ptile xb if plot & cond==4, msize(vsmall) color(red) lpattern(dash)), ///
		text(9 `upperlim' "p-value KS-test no/full exposure: `KSpval1'", placement("sw")) ///
		text(4 `upperlim' " low/high exposure: `KSpval2'", placement("sw")) ///
	ytitle("Percentile of firms") ylabel(0(10)90, grid) legend(label(1 "No exposure") label(2 "Full exposure") label(3 "Exposure in (0.02,0.5]") label(4 "Exposure in (0.5,0.98)") rows(2)) `options'
	}
	
	drop insample_plot xb ptile plot
end

cap program drop addKS
program addKS, nclass
	syntax varlist [if], est(string)
	cap mat drop A
	cap mat drop B
	forval i = 1 / 4 {
		foreach var of loc varlist {
			di "`var' `i'"
			
			cap drop xb
			qui areg `var' `if', a(nace)
			predict xb, xbd
			replace xb = `var' - xb + _b[_cons]
			_crcslbl xb `var'
			
			if `i' == 2 {
				qui ksmirnov xb `if', by(KScat1)
				mat B = r(p)
				mat rownames B = "2:`var'"
			}
			else if `i' == 4 {
				qui ksmirnov xb `if', by(KScat2)
				mat B = r(p)
				mat rownames B = "4:`var'"
			}
			else {
				mat B = .
				mat rownames B = "`i':`var'"
			}
			
			cap mat li A
			if _rc == 0 {
				mat A = A \ B
			}
			else {
				mat A = B
			}
		}
	}
	mat colnames A = "ks"
	mat A = A'
	mat li A
	
	estadd matrix ks = A : `est'
end


********************************************************************************
* Load data
********************************************************************************

use $cleandatapath/PPI/out/monthly/ppi_domestic, clear
keep if inrange(year, 2004, 2010)
collapse (firstnm) cvrnr (sum) Dp2, by(panid year)
collapse (mean) Dp2, by(cvrnr year)
replace Dp2 = Dp2*100
save $path/temp/Dp_ppi, replace

use $projectpath/analysis/4_did_uhdm/temp/panel, replace 
keep if inrange(year, 2004, 2010)
gcollapse (mean) Duv1, by(cvrnr year)
replace Duv1 = Duv1*100
save $path/temp/Duv_uhdm, replace

use $projectpath/data/3_sample/out/panel, replace
merge m:1 cvrnr using $projectpath/data/5_demand_elasticities/temp/firmlvl_DE_PPIfirms, keep(match master) keepus(sigmaBW_PPI) nogen
merge m:1 cvrnr using $projectpath/data/5_demand_elasticities/temp/firmlvl_DE_UHDMfirms, keep(match master) keepus(sigmaBW_UHDM) nogen
merge 1:1 cvrnr year using $path/temp/Dp_ppi, keep(match master) nogen
merge 1:1 cvrnr year using $path/temp/Duv_uhdm, keep(match master) nogen

global sample = "loans_uv06>100 & loans_uv07>100 & loans_to_revenue07>0.01"
global period = "inrange(year,2005,2010)"
distinct cvrnr if $sample & $period 

********************************************************************************
* distribution of treatment 
********************************************************************************

count if year==2007 & $sample & !mi(tt_uvall) & (inPPI | inUHDM) & $sample
loc total = r(N)
count if year==2007 & $sample & !mi(tt_uvall) & tt_uvall<=0.02 & (inPPI | inUHDM) & $sample
loc zero = r(N)
count if year==2007 & $sample & !mi(tt_uvall) & tt_uvall>=0.98 & (inPPI | inUHDM) & $sample
loc one = r(N)
loc zeroshare = `zero'/`total'
loc oneshare = `one' / `total'
twoway (hist tt_uvall if year==2007 & $sample & (inPPI | inUHDM), frac bin(25) color(green%30)) ///
	(pci 0 0 `zeroshare' 0, color(blue) lp(solid)) ///
	(scatteri `zeroshare' 0, color(blue) msymbol(o)) ///
	(pci 0 1 `oneshare' 1, color(blue) lp(solid)) ///
	(scatteri `oneshare' 1, color(blue) msymbol(o)), ///
	ytitle("Fraction of firms") xtitle("Share of loans from exposed banks in 2007") legend(order(3 "Full or no exposure" 1 "Binned distribution of exposure") rows(1)) ylabel(0(0.05)0.4)
graph export $folder/FigA4_treatment_distribution.pdf, as(pdf) replace

********************************************************************************
* Low loans vs in sample
********************************************************************************

cap drop cond
gen cond = 1 if $sample
replace cond = 2 if (loans_uv06<100 | loans_uv07<100 | loans_to_revenue07<0.01)

* Percentile plot of loans / debt
preserve
	keep if year==2007 & inlist(cond,1,2) & !mi(akg07) & !mi(alg07)
	cap gen reldebt = loans_uv07 / (akg07 + alg07) 
	areg reldebt, a(nace)
	cap drop xb
	predict xb, xbd
	replace reldebt = reldebt-xb+_b[_cons]
	bys cond (reldebt): gen ptile = int(100*(_n-1)/_N)+1
	bys cond ptile (reldebt): gen plot = _n==_N & inlist(ptile,10,20,30,40,50,60,70,80,90)
	twoway (connected ptile reldebt if plot & cond==1, color(blue) lpattern(solid)) ///
	(connected ptile reldebt if plot & cond==2, color(red) lpattern(dash)), ///
	ytitle("Percentile of firms") xtitle("Bank loans to balance sheet debt") xlabel(0(0.1)0.9, grid) ylabel(0(10)90, grid) legend(label(1 "In sample") label(2 "Loans too low") label(3 "Exposure in (0.02,0.5]") label(4 "Exposure in (0.5,0.98)") rows(1))
restore
graph export $folder/FigA1b_loans_to_debt_bysample.pdf, as(pdf) replace

* Percentile plot of debt to assets
preserve
	keep if year==2007 & inlist(cond,1,2) & !mi(akg07) & !mi(alg07)
	cap gen reldebt = (akg07 + alg07) / past07
	areg reldebt, a(nace)
	cap drop xb
	predict xb, xbd
	replace reldebt = reldebt-xb+_b[_cons]
	bys cond (reldebt): gen ptile = int(100*(_n-1)/_N)+1
	bys cond ptile (reldebt): gen plot = _n==_N & inlist(ptile,10,20,30,40,50,60,70,80,90)
	twoway (connected ptile reldebt if plot & cond==1, color(blue) lpattern(solid)) ///
	(connected ptile reldebt if plot & cond==2, color(red) lpattern(dash)), ///
	ytitle("Percentile of firms") xtitle("Debt to assets") xlabel(0.1(0.1)0.8, grid) ylabel(0(10)90, grid) legend(label(1 "In sample") label(2 "Loans too low") label(3 "Exposure in (0.02,0.5]") label(4 "Exposure in (0.5,0.98)") rows(1))
restore
graph export $folder/FigA1a_debt_to_assets_bysample.pdf, as(pdf) replace

********************************************************************************
* Interest rate validation
********************************************************************************

preserve
	cap drop xtile
	keep if $sample & $period
	drop if mi(interest_rate_ctr) | interest_rate_ctr == 0
	sort interest_rate_ctr
	gquantiles xtile = interest_rate_ctr, xtile nquantiles(20)  
	winsor2 interest_rate, cut(10 90) replace by(xtile)
	reg interest_rate interest_rate_ctr if interest_rate_ctr<0.1 & $sample & $period, nocons
	loc corr01 = round(_b[interest_rate_ctr], 0.01)
	reg interest_rate interest_rate_ctr if $sample & $period, nocons
	loc corr = round(_b[interest_rate_ctr], 0.01)
	gcollapse (median) interest_rate_ctr interest_rate, by(xtile)
	twoway (scatter interest_rate interest_rate_ctr if xtile<18) (function y = x, range(0 0.1)), ///
	text(0.01 0.12 "Coefficient for i<0.1: `corr01'", placement("sw")) ///
	text(0.015 0.12 "Coefficient: `corr'", placement("sw")) ///
	xlabel(0(0.025)0.125) ylabel(0(0.025)0.1) legend(off) ytitle("Avg. imputed interest rate") xtitle("Avg. contractual interest rate")
restore
graph export $folder/FigA3_interest_rate_validation.pdf, as(pdf) replace

********************************************************************************
* Treatment vs control 
********************************************************************************

cap drop cond
gen cond = .
replace cond = 1 if tt_uvall<0.5 & pbshare07>=0.98   
replace cond = 2 if tt_uvall>=0.5 & pbshare07>=0.98 
replace cond = 3 if tt_uvall<0.5 & pbshare07<0.98  
replace cond = 4 if tt_uvall>=0.5 & pbshare07<0.98 
gen KScat1 = cond == 2
replace KScat1 = . if cond == 3 | cond == 4
tab cond KScat1
gen KScat2 = cond == 4 
replace KScat2 = . if cond == 1 | cond == 2
tab cond KScat2

* sector, by treatment group
preserve
keep if year==2007 & $sample & (inPPI | inUHDM)
tab nace2d, sort
catplot cond nace_grp, percent ylabel(0(2.5)12.5) asyvars bargap(50) ///
	bar(1 , color(white) lcolor(black)) bar(2 , color(red)) ///
	bar(3 , color(white) lcolor(black%70)) bar(4 , color(red%30))  ///
	legend(label(1 "No exposure") label(2 "Full exposure") label(3 "Exposure in (0.02,0.5]") label(4 "Exposure in (0.5,0.98)") rows(2)) var2opts(gap(300) label(alternate) sort(1) descending) outergap(*.1) ytitle("") xsize(12) recast(bar)
graph export $folder/FigA5_sector_distribution_tt.pdf, as(pdf) replace
restore


********************************************************************************
* distribution table: population vs PPI vs UHDM
********************************************************************************

global varlist_stat = "emp07 firmage04 revenue07mio profit_to_revenue07 loans_to_revenue07_pct reldebt interest_rate connections07 connections_loans07 pbshare07 stshare07 equity_share07 deposits_to_revenue07 inv_to_revenue07 sigmaBW_PPI sigmaBW_UHDM" 
global varlist_dyn = "gemp_pre gemp_GR grevenue_pre grevenue_GR Dp2_pre Dp2_GR Duv1_pre Duv1_GR"

destring cvrnr, replace
xtset cvrnr year
cap gen revenue07mio = revenue07 / 1000
replace profit_to_revenue07 = profit_to_revenue07*100
cap gen reldebt = loans_uv07 / (akg07 + alg07) *100
cap drop interest_rate
gen interest_rate = (interest / (0.5*L.loans_uv + 0.5*loans_uv))*100
replace pbshare07 = pbshare07*100
replace stshare07 = stshare07*100
replace equity_share07 = equity_share07*100
gen loans_to_revenue07_pct = loans_to_revenue07*100
replace deposits_to_revenue07 = deposits_to_revenue07*100
replace inv_to_revenue07 = inv_to_revenue07*100
gen gemp_pre = (emp_firm / L1.emp_firm - 1)*100 if inrange(year, 2004, 2007)
winsor2 gemp_pre, cuts(1 99) by(year) replace
gen gemp_GR = (emp_firm / L1.emp_firm - 1)*100 if inrange(year, 2008, 2010)
winsor2 gemp_GR, cuts(1 99) by(year) replace
gen grevenue_pre = (revenue_firm / L1.revenue_firm - 1)*100 if inrange(year, 2004, 2007)
winsor2 grevenue_pre, cuts(1 99) by(year) replace
gen grevenue_GR = (revenue_firm / L1.revenue_firm - 1)*100 if inrange(year, 2008, 2010)
winsor2 grevenue_GR, cuts(1 99) by(year) replace
gen Dp2_pre = Dp2 if inrange(year, 2004, 2007)
gen Dp2_GR = Dp2 if inrange(year, 2008, 2010)
gen Duv1_pre = Duv1 if inrange(year, 2004, 2007)
gen Duv1_GR = Duv1 if inrange(year, 2008, 2010)

eststo table_all_stat: estpost tabstat $varlist_stat if year==2007 & $sample, columns(statistics) statistics(mean p50)
eststo table_all_dyn: estpost tabstat $varlist_dyn if $sample, columns(statistics) statistics(mean p50)
eststo table_ppi_stat: estpost tabstat $varlist_stat if year==2007 & $sample & inPPI, columns(statistics) statistics(mean p50)
eststo table_ppi_dyn: estpost tabstat $varlist_dyn if $sample & inPPI, columns(statistics) statistics(mean p50)
eststo table_uhdm_stat: estpost tabstat $varlist_stat if year==2007 & $sample & inUHDM, columns(statistics) statistics(mean p50)
eststo table_uhdm_dyn: estpost tabstat $varlist_dyn if $sample & inUHDM, columns(statistics) statistics(mean p50)

esttab table_all_stat table_ppi_stat table_uhdm_stat, cells("mean(fmt(1)) p50(fmt(1))") mlabels("All firms" "PPI match" "Export unit value match")
esttab table_all_dyn table_ppi_dyn table_uhdm_dyn, cells("mean(fmt(1)) p50(fmt(1))") mlabels("All firms" "PPI match" "Export unit value match")

esttab table_all_stat table_ppi_stat table_uhdm_stat using $folder/Tab1_sample_descriptives_part1, cells("mean(fmt(1)) p50(fmt(1))") mlabels("All firms" "PPI match" "Export unit value match") booktabs replace
esttab table_all_dyn table_ppi_dyn table_uhdm_dyn using $folder/Tab1_sample_descriptives_part2, cells("mean(fmt(1)) p50(fmt(1))") mlabels("All firms" "PPI match" "Export unit value match") booktabs replace


********************************************************************************
* Treatment vs control  tables
********************************************************************************

local varlist_stat = "emp07 firmage04 revenue07mio profit_to_revenue07 loans_to_revenue07_pct reldebt interest_rate connections07 connections_loans07 pbshare07 stshare07 equity_share07 deposits_to_revenue07 inv_to_revenue07 sigmaBW_PPI sigmaBW_UHDM"

estpost tabstat `varlist_stat' if year==2007 & $sample & (inPPI | inUHDM), by(cond) stats(p50 mean) columns(statistics) nototal
est sto table_part1
addKS  `varlist_stat' if year==2007 & $sample & (inPPI | inUHDM), est(table_part1)  
esttab table_part1, cells("mean(fmt(1)) p50(fmt(1)) ks(fmt(2) keep(2:* 4:*))") unstack  noobs label mtitles("No exposure" "Full exposure" "Low partial exposure" "High partial exposure")
esttab table_part1 using $folder/TabA2_sample_descriptives_part1, cells("mean(fmt(1)) p50(fmt(1)) ks(fmt(2) keep(2:* 4:*))") unstack  noobs label mtitles("No exposure" "Full exposure" "Low partial exposure" "High partial exposure") booktabs replace

replace Dp2_pre = . if inPPI != 1
replace Duv1_pre = . if inUHDM != 1
estpost tabstat gemp_pre grevenue_pre Dp2_pre Duv1_pre if $sample & (inPPI | inUHDM), by(cond) stats(p50 mean) columns(statistics) nototal
est sto table_part2
addKS  gemp_pre grevenue_pre Dp2_pre Duv1_pre if $sample & (inPPI | inUHDM), est(table_part2)  
esttab table_part2, cells("mean(fmt(1)) p50(fmt(1)) ks(fmt(2) keep(2:* 4:*))") unstack  noobs label mtitles("No exposure" "Full exposure" "Low partial exposure" "High partial exposure")
esttab table_part2 using $folder/TabA2_sample_descriptives_part2, cells("mean(fmt(1)) p50(fmt(1)) ks(fmt(2) keep(2:* 4:*))") unstack  noobs label mtitles("No exposure" "Full exposure" "Low partial exposure" "High partial exposure") booktabs replace

