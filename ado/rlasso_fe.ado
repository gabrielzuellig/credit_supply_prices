program rlasso_fe, rclass
syntax [if], absorbtt(string) absorbdid(string) x(string) y(string) tt(string) [weights(string) resid(string)]

if "`resid'"!=""{
	loc resid="resid(`resid')"
}

if "`weights'" != "" {
	loc weightstr = "[aw = `weights']"
}

** tt predictors
loc rlassostr = ""
foreach var in `tt' `x'  {
	cap drop `var'_r1
	qui reghdfe `var' `if' & year==2007 `weightstr', absorb(`absorbtt') resid(`var'_r1)
	loc rlassostr = "`rlassostr' `var'_r1"
}
qui rlasso `rlassostr' `weightstr'
loc tt_predictors = e(selected)
loc tt_predictors = subinstr("`tt_predictors'", "_r1", "", .)
*di as error "`tt_predictors'"

** y predictors
loc rlassostr = ""
cap drop `y'_r2
qui reghdfe `y' `if', absorb(`absorbdid') resid(`y'_r2)
foreach var in `x'  {
	forval year = 2005/2010 {
		cap drop `var'_`year'
		qui gen `var'_`year' = `var' * (year==`year')
		cap drop `var'_`year'_r2
		qui reghdfe `var'_`year' `if' `weightstr', absorb(`absorbdid') resid(`var'_`year'_r2)
		loc rlassostr = "`rlassostr' `var'_`year'_r2"
	}
}
qui rlasso `y'_r2 `rlassostr' `weightstr'
loc y_predictors = e(selected)
loc y_predictors = subinstr("`y_predictors'", "_r2", "", .)

while regexm("`y_predictors'", "([a-zA-Z0-9_]+)_(20[01][0-9])") {
	loc y_predictors = subinstr("`y_predictors'", regexs(1)+"_"+regexs(2), "c."+regexs(1), 1)
}
*di "`y_predictors'"
if "`y_predictors'" == "." {
	loc y_predictors = "" 
}

* fix duplicates
loc tt_predictors2 = ""
loc y_predictors2 = ""
foreach var in `y_predictors' {
	if !regexm("`y_predictors2'", "`var'") {
		loc y_predictors2 = "`y_predictors2' `var'"
	}
}
foreach var in `tt_predictors' {
	if !regexm("`tt_predictors2'", "`var'") {
		loc tt_predictors2 = "`tt_predictors2' `var'"
	}
}
loc tt_predictors = "`tt_predictors2'"
loc y_predictors = "`y_predictors2'"

loc predictors_c = ""
foreach var in `tt_predictors' `y_predictors' {
	loc predictors_c = "`predictors_c' c.`var'"
}

reghdfe `y' ib2007.year##c.`tt' ib2007.year##(`predictors_c') `if'  `weightstr', absorb(`absorbdid') vce(cl cvrnr) `resid'
estadd local y_predictors = "`y_predictors'" 
estadd local tt_predictors = "`tt_predictors'"

end