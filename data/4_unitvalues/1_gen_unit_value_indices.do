/*

	1_GEN_UNIT_VALUE_INDICES:
	
	Prepare export unit values: Map CN across time and create firm-CN2-level UV indices

	DEPENDENCIES:
	
	Inputs:
	 - TO DO

	Outputs:
	 - uvall.dta, to be called by analysis/4_did_uhdm

*/

global path = "$projectpath/data/4_unitvalues"
cap mkdir $path/out
cap mkdir $path/temp

********************************************************************************
* Mapping function
********************************************************************************

cap program drop construct_index
program def construct_index, nclass
syntax anything, mapping(string) data(string) output(string) cn_digits(integer) panelvars(string)

********************************************************************************
* Calculate mapping given CN mapping and firm data
********************************************************************************

* load mapping
use `mapping', clear

* replicate all potential edges for each cvrnr and CN8_2 combinations
rename CN8_2 CN8
rename year_2 year
joinby CN8 year using `data'
rename CN8 CN8_2
rename year year_2
rename value value_2
rename quant quant_2
rename weight weight_2
rename unit unit_2
rename kg_per_unit kg_per_unit_2
descr

* merge actual CN8_1 values; keep only existing edges
rename CN8_1 CN8
rename year_1 year
merge m:1 CN8 year `panelvars' using `data', keep(match)
rename CN8 CN8_1
rename year year_1
rename value value_1
rename quant quant_1
rename weight weight_1
rename unit unit_1
rename kg_per_unit kg_per_unit_1

* drop zero-value maps
drop if value_1==0 | value_1==. | quant_1==0 | quant_1==. | value_2==0 | value_2==. | quant_2==0 | quant_2==.
keep `panelvars' value_2 quant_2 weight_2 CN8_2 year_2 CN8_1 year_1 value_1 quant_1 weight_1 map_type_CN unit_1 unit_2 kg_per_unit_1 kg_per_unit_2

* generate bipartite graph ids
cap drop nodeid*
gegen nodeid_1 = group(`panelvars' year_1 CN8_1)
sum nodeid_1
loc add = r(max)
gegen nodeid_2 = group(`panelvars' year_2 CN8_2)
replace nodeid_2 = nodeid_2+`add'
group_twoway nodeid_1 nodeid_2, gen(map_id)

* classify graphs
gegen dum_1 = tag(CN8_1 map_id `panelvars')
gegen no_of_vertices_1 = total(dum_1), by(map_id `panelvars')
gegen dum_2 = tag(CN8_2 map_id `panelvars')
gegen no_of_vertices_2 = total(dum_2), by(map_id `panelvars')

gegen repeats_1 = count(value_2), by(CN8_1 `panelvars')

gen map_type_cvr = 1 if no_of_vertices_1 == 1 & no_of_vertices_2==1
replace map_type_cvr = 2 if no_of_vertices_1>1 & no_of_vertices_2==1
replace map_type_cvr = 3 if no_of_vertices_1==1 & no_of_vertices_2>1
replace map_type_cvr = 4 if no_of_vertices_1>1 & no_of_vertices_2>1
label def maps 1 "1:1" 2 "m:1" 3 "1:m" 4 "m:m", replace
label values map_type_cvr maps

********************************************************************************
* gen reference quantities and values
********************************************************************************

replace weight_1 = quant_1 * kg_per_unit_1 if weight_1==.
replace weight_2 = quant_2 * kg_per_unit_2 if weight_2==.

gegen quant_ref_1 = total(quant_1 * dum_1), by(map_id)
gegen value_ref_1 = total(value_1 * dum_1), by(map_id)
gegen quant_ref_2 = total(quant_2 * dum_2), by(map_id)
gegen value_ref_2 = total(value_2 * dum_2), by(map_id)
gegen weight_ref_1 = total(weight_1 * dum_1), by(map_id)
gegen weight_ref_2 = total(weight_2 * dum_2), by(map_id)
gen uv1_ref_1 = value_ref_1 / quant_ref_1
gen uv1_ref_2 = value_ref_2 / quant_ref_2
gen uv2_ref_1 = value_ref_1 / weight_ref_1
gen uv2_ref_2 = value_ref_2 / weight_ref_2
gen Duv1_ref = log(uv1_ref_2 / uv1_ref_1)
gen Duv2_ref = log(uv2_ref_2 / uv2_ref_1)

* check unit consistency within mapping
gegen multiunit_within_1 = sd(unit_1), by(map_id)
gegen multiunit_within_2 = sd(unit_2), by(map_id)
count if multiunit_within_1 == .
di as error r(N)
replace multiunit_within_1 = 0 if multiunit_within_1==.
replace multiunit_within_2 = 0 if multiunit_within_2==.
gen tmp = abs(unit_1 - unit_2)
gegen multiunit_time = total(tmp), by(map_id)
count if multiunit_within_1!=0 | multiunit_within_2!=0 | multiunit_time!=0
replace Duv1_ref = Duv2_ref if multiunit_within_1!=0 | multiunit_within_2!=0 | multiunit_time!=0

********************************************************************************
* collapse to index
********************************************************************************

* 1:1 mapping, m:1 mapping
gen weight = value_1
* 1:m mapping
replace weight = value_1 / repeats_1 if map_type_cvr==3 | map_type_cvr == 4

loc cn_var = "CN`cn_digits'"

gen `cn_var' = substr(CN8_2, 1, `cn_digits')
gen prod_in_index = dum_1

* winsorize
replace Duv1_ref = 1 if Duv1_ref>1 & !mi(Duv1_ref)
replace Duv1_ref = -1 if Duv1_ref<-1 & !mi(Duv1_ref)
replace Duv2_ref = 1 if Duv2_ref>1 & !mi(Duv2_ref)
replace Duv2_ref = -1 if Duv2_ref<-1 & !mi(Duv2_ref)

gen value_in_1 = value_1 * dum_1
gen value_in_2 = value_2 * dum_2
gen share_11 = (map_type_cvr == 1)*value_1*dum_1
gen share_m1 = (map_type_cvr == 2)*value_1*dum_1
gen share_1m = (map_type_cvr == 3)*value_1*dum_1
gen share_mm = (map_type_cvr == 4)*value_1*dum_1

gcollapse (mean) Duv1_ref Duv2_ref (rawsum) prod_in_index value_in_2 value_in_1 share_11 share_m1 share_1m share_mm [weight=weight], by(`cn_var' cvrnr year_2)
rename year_2 year

rename Duv1_ref Duv1
rename Duv2_ref Duv2
replace share_11 = share_11 / value_in_1
replace share_m1 = share_m1 / value_in_1
replace share_1m = share_1m / value_in_1
replace share_mm = share_mm / value_in_1

sum Duv1 Duv2

bys cvrnr `cn_var' (year): gen spell_start=year[_n-1]!=year-1
bys cvrnr `cn_var' (year): gen spell_id = sum(spell_start)
expand 2 if spell_start==1, gen(base)
replace year = year-1 if base==1
replace spell_start=0 if spell_start==1 & base==0
replace Duv1 = . if base == 1
replace Duv2 = . if base == 1

bys cvrnr `cn_var' (year): gen luv1 = sum(Duv1)
bys cvrnr `cn_var' (year): gen luv2 = sum(Duv2)

drop base spell_start spell_id

save `output', replace

use `data', clear
gen `cn_var' = substr(CN8,1,`cn_digits')
gcollapse (sum) value quant weight, by(cvrnr `cn_var' year)
merge 1:1 cvrnr year `cn_var' using `output', keep(match using) nogen
gen share_coverage = value/value_in_2
save `output', replace

end

* impute price forward so that price changes after period of missings are attributed to period when product reappears
cap program drop impute
program def impute, nclass
syntax [anything], panelvars(string)

bys `panelvars' (year): gen forward_gap = year[_n+1]-year-1
replace forward_gap = 0 if forward_gap == .

gen obsid = _n
gen imputed = 0
forval x=1/25 {
	expand `=`x'+1' if forward_gap==`x', gen(tmp)
	replace imputed = 1 if tmp == 1
	tab tmp
	cap drop tmp
}
bys obsid imputed: gen year_new=year+_n
replace year=year_new if imputed
drop year_new
bys obsid (year): keep if _n==1 | _n==_N

end


********************************************************************************
* prepare mapping at CN level
********************************************************************************
use "$path/out/CN_panel.dta", clear
keep CN8 year
rename CN8 start_code
rename year start_year

joinby start_code start_year using $path/out/CN_transitions.dta, unmatched(both)
rename start_code CN8_2
rename start_year year_2
rename end_code CN8_1
rename end_year year_1
replace CN8_1 = CN8_2 if CN8_1==""
replace year_1 = year_2-1 if year_1==.
keep year_1 year_2 CN8_1 CN8_2

* generate bipartite node ids
cap drop nodeid*
gegen nodeid_1 = group(year_1 CN8_1)
sum nodeid_1
loc add = r(max)
gegen nodeid_2 = group(year_2 CN8_2)
replace nodeid_2 = nodeid_2+`add'

group_twoway nodeid_1 nodeid_2, gen(map_id_CN)
drop nodeid_1 nodeid_2

gegen dum_1 = tag(CN8_1 map_id_CN)
gegen no_of_vertices_1 = total(dum_1), by(map_id_CN)
gegen dum_2 = tag(CN8_2 map_id_CN)
gegen no_of_vertices_2 = total(dum_2), by(map_id_CN)

gen map_type_CN = 1 if no_of_vertices_1 == 1 & no_of_vertices_2==1
replace map_type_CN = 2 if no_of_vertices_1>1 & no_of_vertices_2==1
replace map_type_CN = 3 if no_of_vertices_1==1 & no_of_vertices_2>1
replace map_type_CN = 4 if no_of_vertices_1>1 & no_of_vertices_2>1
label def maps 1 "1:1" 2 "m:1" 3 "1:m" 4 "m:m", replace
label values map_type_CN maps

keep CN8_1 CN8_2 year_1 year_2 map_type map_id
save $path/temp/complete_mapping, replace


********************************************************************************
* prepare export data
********************************************************************************

global path = "$projectpath/data/4_unitvalues"
cap mkdir $path/out
cap mkdir $path/temp

use "$cleandatapath/UHDM/out/UHDM_exports.dta", clear
drop if quant == 0 | value==0 | mi(quant) | mi(value)
bys cvrnr year CN8 country unit: gen dum = _n==1

gcollapse (sum) quant value weight dum, by(cvrnr year CN8 country)

save $path/out/exportdata_countries, replace


use "$cleandatapath/UHDM/out/UHDM_exports.dta", clear
count if quant == . | quant == 0
count if weight == . | weight == 0
drop if value == . | value == 0
drop if (quant == . | quant == 0) & (weight==. | weight==0)
gcollapse (sum) value quant weight, by(cvrnr year CN8 unit)

gen tmp = weight/quant
gegen kg_per_unit = mean(tmp), by(year CN8)
cap drop tmp

impute, panelvars(cvrnr CN8)

save $path/out/exportdata, replace


********************************************************************************
* Calculate indices
********************************************************************************

construct_index asdf, data($path/out/exportdata) mapping($path/temp/complete_mapping) output($path/out/uv_all) cn_digits(2) panelvars(cvrnr)


********************************************************************************
* Calculate totals by country and product
********************************************************************************

use "$cleandatapath/UHDM/out/UHDM_exports.dta", clear
drop if quant == 0 | value==0 | mi(quant) | mi(value)
bys cvrnr year CN8 country unit: gen dum = _n==1

gcollapse (sum) quant value weight dum, by(cvrnr year CN8 country)

save $path/out/exportdata_countries, replace
