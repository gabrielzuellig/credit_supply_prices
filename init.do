* Define global settings for entire project

global projectpath = "E:\ProjektDB\706172\Workdata\707904\FinancialFrictions_final_replication_package"

global cleandatapath = "E:\ProjektDB\706172\Rawdata\707904\CLEANDATA"

global firepath = "${projectpath}\data\01_firm_balance_sheet"

global urtepath = "${projectpath}\data\02_firm_bank_links"

global tradepath = "${cleandatapath}\UHDM\out\"

global startyear = 2001

global endyear = 2016

run "${projectpath}\labelling.do"

sysdir set PERSONAL "${projectpath}\ado" 

* coefplot labels
global xlabel = ""
forval tq = `=yq(1995,1)'/`=yq(2020,4)' {
	local yearstr = substr("`=year(dofq(`tq'))''",3,2)
	local quarter = quarter(dofq(`tq'))
	global xlabel = "$xlabel" + "`tq'.tq = `yearstr'q`quarter' "
}
forval th = `=yh(1995,1)'/`=yh(2020,2)' {
	local yearstr = substr("`=year(dofh(`th'))''",3,2)
	local half = halfyear(dofh(`th'))
	global xlabel = "$xlabel" + "`th'.th = `yearstr'h`half' "
}
forval year = 1990/2020 {
	local yearstr = substr("`year'",3,2)
	global xlabel = "$xlabel" + "`year'.year = `yearstr' "
}
forval year = 1990/2020 {
	local yearstr = substr("`year'",3,2)
	global xlabel2 = "$xlabel2" + "`year'.year#c.ltd = `yearstr' "
}
forval year = 1990/2020 {
	local yearstr = substr("`year'",3,2)
	global xlabel3 = "$xlabel3" + "`year'.year#c.ltd_pb = `yearstr' "
}

global coefplot_settings = "yline(0, lcolor(gs9)) vertical recast(connected) ciopt(recast(rcap) lpattern(solid)) coeflabel($xlabel, alternate) omitted baselevels"
global coefplot_settings_noalt = "yline(0, lcolor(gs9)) vertical recast(connected) ciopt(recast(rcap) lpattern(solid)) coeflabel($xlabel) omitted baselevels"
global coefplot_settings2 = "yline(0, lcolor(gs9)) vertical recast(connected) ciopt(recast(rcap) lpattern(solid)) coeflabel($xlabel, alternate) omitted baselevels levels(90)"
global coefplot_settings3 = "yline(0, lcolor(gs9)) vertical recast(connected) ciopt(recast(rcap) lpattern(solid)) levels(90) coeflabel($xlabel2, alternate) omitted baselevels legend(pos(6) r(1))"
global coefplot_settings4 = "yline(0, lcolor(gs9)) vertical recast(connected) ciopt(recast(rcap) lpattern(solid)) levels(90) coeflabel($xlabel3, alternate) omitted baselevels legend(pos(6) r(1))"
global coefplot_settings5 = "yline(0, lcolor(gs9)) vertical recast(connected) ciopt(recast(rcap) lpattern(solid)) coeflabel($xlabel, alternate) omitted baselevels"


global esttab_settings = "noomitted nobaselevels se label star(* 0.1 ** 0.05 *** 0.01) nodepvar nonotes"
global esttab_rename = "rename(1.period#c.tt_uvall 1.period 2.period#c.tt_uvall 2.period 3.period#c.tt_uvall 3.period)"
global esttab_rename_years = "rename(2008.year#c.tt_uvall 2008.year 2009.year#c.tt_uvall 2009.year 2010.year#c.tt_uvall 2010.year)"
global esttab_tabularx = `"nogap fragment prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \begin{tabularx}{\textwidth}{l*{@M}{>{\centering\arraybackslash}X}}\toprule") posthead("\midrule") prefoot("\midrule")  postfoot("\bottomrule\end{tabularx}}")"'
global esttab_tabularx1 = `"nogap fragment prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi} \begin{tabularx}{\textwidth}{l*{@M}{>{\centering\arraybackslash}X}}\toprule") posthead("\midrule")"'
global esttab_tabularxk = `"nogap fragment"'
global esttab_tabularxn = `"nogap fragment prefoot("\midrule")  postfoot("\bottomrule\end{tabularx}}")"'




global rename_list = "*.th#c.tt_stall2=.th *.th#c.tt_ltall2=.th *.th#c.tt_stall=.th *.th#c.tt_ltall=.th *.th#c.tt_uvall=.th *.year#c.tt_stall2=.year *.year#c.tt_ltall2=.year *.year#c.tt_stall=.year *.year#c.tt_ltall=.year *.year#c.tt_uvall=.year *.year#c.tt_uvbid1=.year *.year#c.tt_uvbid6=.year *.year#c.tt_uvother=.year"

global fe_indicators = `"panid "Firm-product" year#nace "time-4d NACE" yorig#nace "time-4d NACE" year#CN2 "time-2d CN" cvrnr#c.year "Firm trend""'

global hetplot_settings = "recast(connected) ciopt(recast(rcap))"

grstyle clear
set scheme s2color
grstyle init
grstyle color background white
grstyle set margin "3pt 3pt 0pt 0pt": graph
grstyle set symbol, msize(huge)
grstyle set lpattern
grstyle set symbolsize large

graph set window fontface       "Times New Roman"
graph set window fontfacemono   "Times New Roman"
graph set window fontfacesans   "Times New Roman"
graph set window fontfaceserif  "Times New Roman"
graph set window fontfacesymbol "Times New Roman"
