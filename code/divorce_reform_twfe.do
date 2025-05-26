file open log_file_Project_2_appliedmicro.txt using log_file

*===========================================================
* PROJECT B - Applied Microeconometrics
* Replication: Effect of Unilateral Divorce Reform on Female Suicide
* Author: Berken Arslan
*===========================================================

clear all
set more off

*-----------------------------------------------------------
* 1. Load the dataset
*-----------------------------------------------------------
use  "/Users/berkenarslan/Library/CloudStorage/OneDrive-Personal/MASTER/Semester 2/Econ4008-applied microeconometrics/Coursework questions and dataset-20250508/project 2/nofault_divorce.dta"



*-----------------------------------------------------------
* 2. Construct reform year and relative year variables
*-----------------------------------------------------------
gen reform_year = .
bysort state (year): replace reform_year = year if treat == 1 & missing(reform_year)
bysort state (reform_year): replace reform_year = reform_year[_n-1] if missing(reform_year)
bysort state (year): replace reform_year = reform_year[_n-1] if missing(reform_year)

gen rel_year = year - reform_year

* Generate indicator for ever-treated and never-treated states
bysort state (treat): gen ever_treated = treat[_N]
gen never_treated = ever_treated == 0

*-----------------------------------------------------------
* 3. Declare panel structure
*-----------------------------------------------------------
xtset state year

*-----------------------------------------------------------
* 4. Estimate Two-Way Fixed Effects (TWFE) model
*-----------------------------------------------------------
xtreg asmrs treat i.year, fe cluster(state)
eststo twfe_model

*-----------------------------------------------------------
* 5. Estimate event-study model using relative years
*-----------------------------------------------------------
gen rel_year_cat = .
replace rel_year_cat = rel_year if inrange(rel_year, -10, 10)

xi: reg asmrs i.rel_year_cat i.year i.state, cluster(state)
eststo event_study

esttab event_study

coefplot event_study, keep(*rel_year_cat*) ///
    drop(_cons) vertical xline(0, lstyle(foreground)) ///
    ytitle("Effect on Female Suicide Rate") ///
    xtitle("Years Since Reform") ///
    title("Event-Study: Unilateral Divorce Reform") ///
    msymbol(circle) ciopts(recast(rcap))


*-----------------------------------------------------------
* 6. Export TWFE regression table (RTF)
*-----------------------------------------------------------
esttab twfe_model using "twfe_results.rtf", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) keep(treat)

*-----------------------------------------------------------
* 7. Event-study graph (manual, no coefplot)
*-----------------------------------------------------------

* If needed: 
ssc install parmest
parmest, norestore
keep if strpos(parm, "rel_year_cat")
gen rel_year = real(substr(parm, -2, .))
gen ub = estimate + 1.96*stderr
gen lb = estimate - 1.96*stderr

* Plot with confidence intervals
twoway (rcap ub lb rel_year, lcolor(gs10)) ///
       (scatter estimate rel_year, msymbol(circle)), ///
       xline(0, lpattern(dash)) ///
       yline(0, lpattern(dash)) ///
       xtitle("Years Since Reform") ///
       ytitle("Effect on Female Suicide Rate") ///
       title("Event-Study: Unilateral Divorce Reform") ///
       legend(off)

graph export "event_study_plot.png", replace

file close log_file_Project_2_appliedmicro

clear all
set more off

