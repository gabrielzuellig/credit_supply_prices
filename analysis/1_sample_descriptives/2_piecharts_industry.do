/*

	2_PIECHARTS_INDUSTRY:
	
	This file generates bar charts for industry shares at product and firm level

	DEPENDENCIES:
	
	Inputs:
	- $projectpath/analysis/3_did_ppi/temp/panel.dta
	
	- $projectpath/analysis/4_did_uhdm/temp/panel.dta

	Outputs:
	 - Fig C.1

*/

global path = "$projectpath/analysis/1_sample_descriptives"
cd $path
cap mkdir $path/out

********************************************************************************
* PPI
********************************************************************************

* load panel and sample as in baseline regression
use $projectpath/analysis/3_did_ppi/temp/panel, replace

global sample = "has_2007 & has_2008 & has_2009 & has_2010 & loans_uv07>=100 & loans_uv06>=100 & loans_to_revenue07>=0.01 & nationtype==2"
keep if $sample
drop if !inrange(year, 2005, 2010)
global controls = "ib2007.year##c.loans_to_revenue07 ib2007.year##c.deposits_to_revenue07 ib2007.year##c.stshare07 ib2007.year##c.interest_rate07"
global fe = "panid ib2007.year#nace"
global period = "year>=2005 & year<=2010"

reghdfe lprisadj2 ib2007.year##c.tt_uvall $controls if $period & $sample, absorb($fe) cl(cvrnr)
est sto exposure1
gen baselinesmpl = e(sample)
distinct cvrnr if baselinesmpl
keep if baselinesmpl

* plot sector composition
distinct nace2d if baselinesmpl // 21 different sectors 
tab nace2d if baselinesmpl
bys cvrnr: gen uniquefirm = _n == 1
tab nace2d if uniquefirm
bys panid: gen uniqueproduct = _n == 1
do $projectpath/labelling
cap graph drop pie_firms_ppi pie_products_ppi
graph pie if uniquefirm, over(nace2d_plot) legend(pos(3) c(1) size(vsmall) symx(3)) name(pie_firms_ppi) title("Firms in PPI", size(small))
graph pie if uniqueproduct, over(nace2d_plot) legend(off) name(pie_products_ppi) title("Products in PPI", size(small))


********************************************************************************
* UHDM
********************************************************************************

* load panel and sample as in baseline regression
use $projectpath/analysis/4_did_uhdm/temp/panel, replace

global sample_all = "loans_to_revenue07>0.01 & loans_uv07>100 & loans_uv06>100 & has_2005 & has_2006 & has_2007 & has_2008 & has_2009 & has_2010"
keep if $sample_all
drop if !inrange(year, 2005, 2010)
global controls = "ib2007.year##c.loans_to_revenue07 ib2007.year##c.deposits_to_revenue07 ib2007.year##c.stshare07 ib2007.year##c.interest_rate07"
global period = "year>=2005 & year<=2010"

reghdfe luv1 ib2007.year##c.tt_uvall $controls if $period & $sample_all, absorb(panid year#nace) cl(cvrnr) 
eststo_wrap, model("prices_baseline_all")
gen baselinesmpl = e(sample)
distinct cvrnr if baselinesmpl 
keep if baselinesmpl

* plot sector composition
distinct nace2d if baselinesmpl // 22 different sectors 
tab nace2d if baselinesmpl
bys cvrnr: gen uniquefirm = _n == 1
tab nace2d if uniquefirm
bys panid: gen uniqueproduct = _n == 1
do $projectpath/labelling
cap graph drop pie_firms_uhdm pie_products_uhdm
graph pie if uniquefirm, over(nace2d_plot) legend(off) name(pie_firms_uhdm) title("Firms in export unit values", size(small))
graph pie if uniqueproduct, over(nace2d_plot) legend(off) name(pie_products_uhdm) title("Products in export unit values" , size(small))


********************************************************************************
* Compile plots about industry composition of samples
********************************************************************************			
		
grc1leg pie_firms_ppi pie_firms_uhdm pie_products_ppi pie_products_uhdm, col(2) iscale(1) legendfrom(pie_firms_ppi) pos(3) 
graph export "${path}/out/FigC1_inducomp.pdf", as(pdf) replace



