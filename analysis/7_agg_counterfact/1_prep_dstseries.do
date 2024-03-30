global path = "$projectpath/analysis/7_agg_counterfact"
cd $path
cap mkdir $path/out
cap mkdir $folder


*******************************************************************************
*** Prepare aggregate/published PPI from DST
*******************************************************************************
 
* import
import delim $path/in/PRIS4315.txt, clear
rename (v1 v2) (time ppi_dstmanu)
gen year = real(substr(time, 1, 4))
gen month = real(substr(time, 6, 7))
gen tm = mofd(mdy(month, 1, year))
format tm %tm

* quarterly frequency
gen tq = qofd(dofm(tm)) + 1
collapse (first) year (first) ppi*, by(tq)
tsset tq

* index to 2007q4
replace ppi_dstmanu = log(ppi_dstmanu)
sum ppi_dstmanu if tq == 191
replace ppi_dstmanu = ppi_dstmanu - r(mean)
format tq %tq

* figures
graph twoway (line ppi_dstmanu tq)

*save
save $path/temp/dst_series, replace



*******************************************************************************
*** Industry weights for aggregate PPI
*******************************************************************************

// industry weights from DST PPI construction (only year 2009)
import delim $path/in/weights.txt, clear
rename (v1 v2 v3 v4) (indu w_domestic w_export w_total)

gen nace2d = real(indu)
egen tot_manudom = total(w_domestic) if nace2d ~= .
gen indw_dst09_dommanu = w_domestic / tot_manudom
keep if nace2d ~= .
keep nace2d indw_dst09_dommanu

save $path/temp/indweights_dst09, replace



