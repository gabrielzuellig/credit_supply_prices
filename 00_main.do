
*** Program setup
capture log close
clear all
macro drop _all
set more off
set segmentsize 2g
program drop _all
set maxvar 20000
set matsize 11000


*** Set paths and global settings
run "E:\ProjektDB\706172\Workdata\707904\FinancialFrictions_final_replication_package\init.do"


************************************************************
************************** Data ****************************
************************************************************

*** Prepare loan-level data
do $projectpath/data/1_combine_irtevirk_urtevirk/1_gen_combine.do

*** Prepare bank level data
do $projectpath/data/2_bank_data/1_gen_bank_panel

*** Firm sample
do $projectpath/data/3_sample/1_gen_exposure
do $projectpath/data/3_sample/2_gen_sample_2007
// Then, we compile EU market size by 4-digit NACE on an open machine. Run 
// 3_marketsizeEU.R in R, which saves a csv and a dta file which we then transferred to
// the Statistics Denmark server.
do $projectpath/data/3_sample/4_gen_panel

*** Prepare unit value indices at firm-CN2 level
do $projectpath/data/4_unitvalues/0_gen_CN_panel.do
do $projectpath/data/4_unitvalues/0_gen_CN_transitions.do
do $projectpath/data/4_unitvalues/1_gen_unit_value_indices

*** Product-specific heterogeneities (demand elasticity, strat. compl.)
// First, we compile the distribution of demand elasticities in the EU and Danish
// PRODCOM data on an open computer (not Statistics Denmark. 
// Run 1_DE_distrib_PRODCOM.R, which saves a csv and a dta file which we then transferred to the Statistics Denmark computer.
do $projectpath/data/5_demand_elasticities/2_DE_prepare_broda_weinstein
do $projectpath/data/5_demand_elasticities/3_DE_aggregated
do $projectpath/data/5_demand_elasticities/4_DE_distributions
do $projectpath/data/5_demand_elasticities/5_SC_compile_exchange_rates
do $projectpath/data/5_demand_elasticities/6_SC_compile_trade_data
do $projectpath/data/5_demand_elasticities/7_SC_regressions
do $projectpath/data/5_demand_elasticities/8_SC_combine_results_byCN2


************************************************************
*********************** Analysis ***************************
************************************************************

*** Descriptive statistics

do $projectpath/analysis/1_sample_descriptives/1_sample_descriptives
do $projectpath/analysis/1_sample_descriptives/2_piecharts_industry
do $projectpath/analysis/1_sample_descriptives/3_loans_micro_vs_balance_sheets
do $projectpath/analysis/1_sample_descriptives/4_uhdm_vs_ppi_comparison  /// TODO: COMMENTS MISSING HERE!


*** First stage 

do $projectpath/analysis/2_firststage/1_firststage_banklevel
do $projectpath/analysis/2_firststage/2_firststage_firmlevel  


*** Price outcomes (reduced-form): PPI

do $projectpath/analysis/3_did_ppi/1_gen_panel
do $projectpath/analysis/3_did_ppi/2_did_ppi
do $projectpath/analysis/3_did_ppi/3_did_ppi_heterogeneity


*** Price outcomes (reduced-form): Export unit values (UHDM)

do $projectpath/analysis/4_did_uhdm/1_gen_panel
do $projectpath/analysis/4_did_uhdm/2_did_uhdm
do $projectpath/analysis/4_did_uhdm/3_did_uhdm_heterogeneity


*** Price outcomes (IV)

do $projectpath/analysis/5_iv/1_gen_ppi_panel
do $projectpath/analysis/5_iv/2_iv_baseline


*** Other firm-level outcomes

do $projectpath/analysis/6_did_firm_outcomes/1_did_firmoutcomes
do $projectpath/analysis/6_did_firm_outcomes/2_average_working_capital


*** Aggregate implications

do $projectpath/analysis/7_agg_counterfact/1_prep_dstseries
do $projectpath/analysis/7_agg_counterfact/2_estimate_cf
do $projectpath/analysis/7_agg_counterfact/3_construct_index
// The remainder of aggregate implications, in particular results in Appendix D
// are produced in Matlab. Manually copy the exported series 'PPImicro'
// into the excel in 7_agg_counterfact/in/data_q_in and run 
// m4_runRemainderAggregate.m. This part is non-confidential and therefore
// provided as part of the replication package.



