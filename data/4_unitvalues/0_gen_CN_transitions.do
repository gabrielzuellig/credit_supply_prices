global path = "$projectpath/data/4_unitvalues"
cap mkdir $path/out
cap mkdir $path/temp

********************************************************************************
import excel using $path\in\CN_2019_update_of_codes_xls.xls, clear firstrow allstring

gen end_year = substr(Period, 1, 4)
gen start_year = substr(Period, 5, 4)
destring end_year, replace
destring start_year, replace
drop Period

rename Origincode end_code
rename Destinationcode start_code

replace end_code = subinstr(end_code, " ", "", .)
replace start_code = subinstr(start_code, " ", "", .)

*bys end_code end_year: gen maps_to_x_starts = _N
*bys start_code start_year: gen maps_from_x_ends = _N

egen group_starts = group(end_code end_year)
egen group_ends = group(start_code start_year)
sum group_starts
replace group_ends = group_ends + r(max)

group_twoway group_starts group_ends, gen(reclass_id)

egen dum_starts = tag(reclass_id start_code)
egen dum_ends = tag(reclass_id end_code)
egen distinct_starts_in_group = total(dum_starts), by(reclass_id)
egen distinct_ends_in_group = total(dum_ends), by(reclass_id)

gen reclass_type = .
replace reclass_type = 3 if distinct_starts_in_group > 1 & distinct_ends_in_group == 1
replace reclass_type = 2 if distinct_starts_in_group == 1 & distinct_ends_in_group > 1
replace reclass_type = 4 if distinct_starts_in_group > 1 & distinct_ends_in_group > 1
replace reclass_type = 1 if distinct_starts_in_group == 1 & distinct_ends_in_group == 1
label define ttype 1 "1:1" 2 "1:m" 3 "m:1" 4 "m:m", replace
label values reclass_type ttype
label variable reclass_type "1=1:1, 2=1:m, 3=m:1, 4=m:m"

sort start_year end_year reclass_id end_code start_code
order start_year end_year reclass_id end_code start_code

tab reclass_type

save $path/out/CN_transitions.dta, replace
