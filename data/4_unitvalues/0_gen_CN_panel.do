global path = "$projectpath/data/4_unitvalues"
cap mkdir $path/out
cap mkdir $path/temp

* extract 8-digit codes from CN definition;
* leave out sections and chapters

forval y=1995/2019 {
	import excel using $path\in\CN_1995_2019.xls, clear sheet("`y'") firstrow allstring
	gen year = `y'
		
	* 2009 needs special treatment
	* CNKEY variable
	* system: padding zeros in the back to 8d + 0090 for chapter/sections or + 0080 for other lines
	* in other files: padded zeros in the back only when line has no sublines
	* for example, 1604 00 00 does not exist because 1604 11 exists; however 1604 11 00 exists because there is nothing below 1601 10
	* problem: I want to remove everything but 8digit reportable lines. 1604 should be removed, 1604 10 00 should stay.
	* conditions for dropping: digits 5678 are "0000" and 4digit code is not unique; digits 78 are "00" and 6digit code is not unique
	
	if `y'==2009 {
		gen Code = substr(CNKEY, 1, 8)
		drop if substr(CNKEY, -2, 2) == "90"
		
		gen code_4d = substr(Code, 1, 4)
		egen count_4d = count(Code), by(code_4d)
		drop if count_4d>1 & substr(Code, 5,4) == "0000"
	
		gen code_6d = substr(Code, 1, 6)
		egen count_6d = count(Code), by(code_6d)
		drop if count_6d>1 & substr(Code, 7,2) == "00"
	}
	drop if Code == ""
	gdistinct Code
	assert(r(N)==r(ndistinct))
	
	rename Code code
	rename Label label
	keep year code label
	
	save "$path/temp/`y'", replace
}

clear
forval y=1995/2019 {
	append using "$path/temp/`y'"
}

* some chapter headings / sections in some years contain roman numerals / letters; no problems here.
drop if regexm(code, "[A-Za-z]+")

* files for some years contain * and spaces. Some leading zeros are missing.
* delete spaces and *; 
* a CN code can only be 7 digits because leading zero is missing; fill up strings with leading zeros to 8d; drop all strings with more than 1 leading zero.
* this should get rid of all chapter/sections/etc. Only reportable 8d hs codes should remain

replace code = subinstr(code, "*", "", .)
replace code = subinstr(code, " ", "", .)
destring code, replace
tostring code, format("%08.0f") replace
drop if substr(code, 1, 2) == "00"

* Codes may be reused!!!!
* Example: 90308920 is "Edge-connected semiconductor production test apparatus, capable of testing the embedded functions in integrated circuits, of a type specified in Additional Note 2 to chapter 90, without recording device" in 1995. Then it disappears in 1996. In 2006 it reappears as "Electronic instruments and appliances for measuring or checking electrical quantities, without recording device, n.e.s.". This is consistent with the documented transitions. Still, one needs to be a bit careful with this it seems.

egen code_num = group(code)
xtset code_num year
gen dum = 1
gen spell_end = F.dum != 1
gen spell_start = L.dum != 1
sort code_num year
by code_num: gen CN8_spell_id = sum(spell_start)
drop code_num dum spell_end spell_start

gegen CN8_spell_start = min(year), by(code CN8_spell_id)
gegen CN8_spell_end = max(year), by(code CN8_spell_id)

rename code CN8

save $path/out/CN_panel.dta, replace
