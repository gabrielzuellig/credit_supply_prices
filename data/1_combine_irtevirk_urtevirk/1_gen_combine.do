/*

	1_gen_combine:
	
	This file creates firm-bank and a firm level panels of total loans, deposits and interest payments.

	DEPENDENCIES:
	
	Inputs:
	
	- $projectpath/data/00_mfi_data_DO_NOT_EXPORT/out/mfi_data_2007
	
	- $cleandatapath\URTEVIRK\out\URTEVIRK_accounts
	
	- $cleandatapath\IRTEVIRK\out\IRTEVIRK_accounts
	
	Outputs:
	
	 - $path/out/firm_bank_panel
	 
	 - $path/out/firm_panel
		
*/

global path = "$projectpath/data/1_combine_irtevirk_urtevirk"
cd $path
cap mkdir out
cap mkdir temp

********************************************************************************
// combine URTEVIRK and IRTEVIRK
********************************************************************************

use $cleandatapath\URTEVIRK\out\URTEVIRK_accounts, clear
append using $cleandatapath\IRTEVIRK\out\IRTEVIRK_accounts, gen(IRTE)

********************************************************************************
// cleanup merge messes
********************************************************************************

/* merge duplicate BANKREGNR entries at largest cvrnr; these are entities that lend through the same banking license but operate under different cvrnr */
preserve
gcollapse (sum) REST_GAELD_BLB, by(bnk_cvrnr BANKRGIST_NR year)
merge m:1 bnk_cvrnr using $projectpath/data/00_mfi_data_DO_NOT_EXPORT/out/mfi_data_2007, keep(match master) keepusing(bid) nogen

gegen total = total(REST_GAELD_BLB), by(BANKRGIST_NR year)
bys BANKRGIST_NR year (REST_GAELD_BLB): gen bnkregnr_share = REST_GAELD_BLB/total
bys BANKRGIST_NR year (REST_GAELD_BLB): gen corr_cvr = bnk_cvrnr[_N] if (bid[_N]!=. | bnkregnr_share[_N]>0.95) & bid==.
keep BANKRGIST_NR year bnk_cvrnr corr_cvr
keep if bnk_cvrnr != corr_cvr & !mi(corr_cvr)
save $path/temp/fix_regnr_dupl, replace
restore

merge m:1 BANKRGIST_NR year bnk_cvrnr using $path/temp/fix_regnr_dupl, nogen keepusing(corr_cvr)
replace bnk_cvrnr = corr_cvr if !mi(corr_cvr)
drop corr_cvr

********************************************************************************
* This can't be exported
********************************************************************************
do E:\ProjektDB\706172\Workdata\707904\FinancialFrictions_backup202203\data\10_combine_irtevirk_urtevirk\99_fix_bad_banks_final_do_not_export.do
********************************************************************************
********************************************************************************

* normalize deposit and loan accounts accounts
gen amount = REST_GAELD_BLB / 1000
replace amount = -ISTAA_BLB / 1000 if IRTE==1

gen interest = RNT_BLB / 1000 * (IRTE==0)
gen interest_deposits = RNT_BLB / 1000 * (IRTE==1)

replace REST_LB_AAR_ANT = 0 if IRTE == 1

sort cvrnr year bnk_cvrnr KTO_NR registmp

rename RNT_FOD_PCT interest_rate_ctr
replace interest_rate_ctr = . if interest_rate_ctr == 0

********************************************************************************
// collapse to unique bnk_cvrnr cvrnr kto_nr combos. 
// joint ownership of accounts both by banks and firms exist, i.e. one kto_nr can map to different firm and bank cvrnr.
********************************************************************************

gcollapse (sum) amount interest interest_deposits (lastnm) registmp interest_rate_ctr REST_LB_AAR_ANT, by(cvrnr year bnk_cvrnr KTO_NR IRTE)
drop if amount<0 & IRTE==0
drop if amount>0 & IRTE==1
gcollapse (sum) amount interest interest_deposits (lastnm) registmp interest_rate_ctr REST_LB_AAR_ANT, by(cvrnr year bnk_cvrnr KTO_NR)

gen debt = amount>=0 & !mi(amount)
gen deposit = amount<0 

bys KTO_NR cvrnr bnk_cvrnr (year): gen stdebt = ((REST_LB_AAR_ANT[1]==0) | (REST_LB_AAR_ANT[1]==.))

bys KTO_NR cvrnr (year): gen pre07 = year[1]<=2007
bys KTO_NR cvrnr (year): gen post07 = year[1]>2007

bys KTO_NR cvrnr (year): gen first = year == year[1] & year != 2003
bys KTO_NR cvrnr (year): gen last = year == year[_N] & year != 2018

gen loans_uv = amount * debt
gen loans_st = loans_uv * stdebt
gen deposits = -amount * deposit

gegen in07 = max((year==2007)), by(KTO_NR cvrnr) 
gen loans_in07 = loans_uv * in07

gen loans_notin07 = loans_uv * !in07

gen loans_pre07 = loans_uv * pre07
gen interest_uv = interest * debt
gen loans_new = loans_uv * first
gen acc = 1

********************************************************************************
// collapse over accounts to firm-bank level
********************************************************************************

replace interest_rate_ctr = interest_rate_ctr * max(loans_uv, 0)
gen sumiwgts = max(loans_uv, 0) * !mi(interest_rate_ctr)

gcollapse (sum) sumiwgts deposits* interest* loans* acc*, by(cvrnr year bnk_cvrnr) fast

merge m:1 bnk_cvrnr using $projectpath/data/00_mfi_data_DO_NOT_EXPORT/out/mfi_data_2007, keep(match master) keepusing(bid ltd) nogen

* determine primary bank in 2007
gen loans07 = loans_uv * (year == 2007) * !mi(ltd)
bys cvrnr (loans07): gen pb_cvrnr = bnk_cvrnr[_N] if !mi(loans07[_N]) & loans07[_N]>0
bys cvrnr (pb_cvrnr): gen pb_bid = bid[_N]

save $path/out/firm_bank_panel, replace

***************************************************************
use $path/out/firm_bank_panel, replace

gen loans = loans_uv
foreach var of varlist loans_* interest* deposits* acc* {
	//gen `var'_all = `var'
	replace `var' = `var' * !mi(ltd)
}

gen loans_pb = loans_uv * (pb_cvrnr == bnk_cvrnr)
gen loans_new_pb = loans_new * (pb_cvrnr == bnk_cvrnr)
gen deposits_pb = deposits * (pb_cvrnr == bnk_cvrnr)
gen interest_pb = interest * (pb_cvrnr == bnk_cvrnr)
gen interest_deposits_pb = interest_deposits * (pb_cvrnr == bnk_cvrnr)

gen connections = !mi(ltd)
gen connections_loans = (loans_uv > 0) * !mi(ltd)
gen connections_deposits = (deposits > 0) * !mi(ltd)

********************************************************************************
// collapse to firm level
********************************************************************************

gcollapse (sum) sumiwgts deposits* interest* loans* connections* acc* (firstnm) pb_bid, by(cvrnr year) fast

replace interest_rate_ctr = interest_rate_ctr / sumiwgts
replace interest_rate_ctr = interest_rate_ctr / 100

save $path/out/firm_panel, replace


