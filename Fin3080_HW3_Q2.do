/*===============================================================================
part1	
	Description:
			In this part, we do necessary data cleaning for answering the question.
			i.e. we conduct Step 1 in this section
						
===============================================================================*/
clear

	/* We first concatenate all raw data files.*/
import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns1.csv"
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns1.dta"
clear

import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns2.csv"
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns2.dta"
clear

use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns1.dta", clear
append using "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns2.dta"

rename ïstkcd stock_id
gen Trd_Week = weekly(trdwnt,"YW")
format Trd_Week %tw

	/* Next, we derive weekly market returns*/
bysort Trd_Week: egen mkt_retnd = mean(wretnd)
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns.dta"
clear

	/* Derive weekly market risk-free returns*/
clear
import excel "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/weekly_risk_free_rate.xlsx", sheet("Sheet1") firstrow

gen Trd_Week = wofd(trading_date_yw)
format Trd_Week %tw

save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/weekly_risk_free_rate.dta"
clear
	
	/* Merge weekly market risk-free returns into list of weekly returns for individual stocka and the whole market*/
use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns.dta", clear

merge m:1 Trd_Week using "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/weekly_risk_free_rate.dta"
drop if _merge != 3
drop _merge
	
	/* Derive individual risk premium and market premium.*/
gen mkt_prm = mkt_retnd - risk_free_return
gen idv_prm = wretnd - risk_free_return

save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns.dta", replace
clear


/*===============================================================================
part2	
	Description:
			In this part, we split data into three periods, denoted by P1, P2, P3.
			i.e. we conduct Step 2 in this section
						
===============================================================================*/
clear

use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns.dta", clear
keep if Trd_Week >= yw(2017,1)
keep if Trd_Week <= yw(2018,52)
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P1.dta"

use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns.dta", clear
keep if Trd_Week >= yw(2019,1)
keep if Trd_Week <= yw(2020,52)
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P2.dta"

use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns.dta", clear
keep if Trd_Week >= yw(2021,1)
keep if Trd_Week <= yw(2022,52)
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P3.dta"
clear


/*===============================================================================
part3
	Description:
			In this part, we deal with data in P1.
			i.e. we conduct Step 3 in this section
						
===============================================================================*/
use"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P1.dta", clear

	/* Distribute data from each individual stock into one group respectively. */
drop if mkt_prm ==.| idv_prm==.
gen beta_i =.
egen stock_group = group(stock_id)

	/* Run time-series regression, estimate a beta_i for each stock i and store results in a new column. */
summarize stock_group, meanonly
local maxvar = r(max)
forvalues i = 1/`maxvar' {
// 	reg idv_prm mkt_prm if stock_group == `i'
	reg wretnd mkt_retnd if stock_group == `i'
	replace beta_i = _b[mkt_retnd] if stock_group == `i'
}

	/* Drop unnecessary data in an effort to increase the accuracy of merging data sets. */
drop trdwnt wretnd Trd_Week mkt_retnd trading_date_yw risk_free_return mkt_prm idv_prm stock_group
	
	/* Delete repeated data. */
duplicates drop stock_id, force

save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P1.dta", replace
clear

/*===============================================================================
part4
	Description:
			In this part, we deal with data in P2.
			i.e. we conduct Step 4 in this section
						
===============================================================================*/
use"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P2.dta", clear

	/* Merge beta_is obtained from Step3 to P2 data set on stock_id. */
merge m:1 stock_id using"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P1.dta"
drop if _merge == 1|_merge == 2
drop _merge

	/* Construct ten portfolios based on beta_i. */
quantiles beta_i, gen(portfolio) nq(10)

	/* Derive weekly portfolio returns. */
bysort Trd_Week portfolio: egen portfolio_return = mean(wretnd)
gen port_prm = portfolio_return - risk_free_return
	
	/* Estimate beta_p for each portfolio over P2. */
drop if mkt_prm==. | port_prm==.
duplicates drop Trd_Week portfolio, force
gen beta_p =.

forvalues i = 1/10 {
	reg port_prm mkt_prm if portfolio == `i'
	replace beta_p = _b[mkt_prm] if portfolio == `i'
}
	/* Delete repeated data. */
duplicates drop portfolio, force

	/* Drop unnecessary data in an effort to increase the accuracy of merging data sets. */
drop stock_id trdwnt wretnd Trd_Week mkt_retnd trading_date_yw risk_free_return mkt_prm idv_prm beta_i portfolio_return port_prm

save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P2.dta", replace
clear


/*===============================================================================
part5
	Description:
			In this part, we deal with data in P3.
			i.e. we conduct Step 5 in this section
						
===============================================================================*/
use"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P3.dta", clear

	/* Merge beta_is obtained from Step3 to P2 data set on stock_id. */
merge m:1 stock_id using"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P1.dta"
drop if _merge == 1|_merge == 2
drop _merge

	/* Construct ten portfolios based on beta_i. */
quantiles beta_i, gen(portfolio) nq(10)

	/* Derive average portfolio returns. */
bysort portfolio: egen avg_portfolio_return = mean(wretnd)
gen port_prm = avg_portfolio_return - risk_free_return
bysort portfolio: egen avg_port_prm = mean(port_prm)

	/* Merge beta_ps obtained from Step4 to P3 data set on porfolio. */
merge m:1 portfolio using"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P2.dta"
drop if _merge == 1|_merge == 2
drop _merge

	/* Regress average portfolio premiums on beta_p for each portfolio over P3. */
drop if beta_p ==.| avg_port_prm==.
duplicates drop portfolio avg_port_prm , force
drop stock_id trdwnt wretnd Trd_Week mkt_retnd trading_date_yw risk_free_return mkt_prm idv_prm beta_i port_prm avg_portfolio_return

reg avg_port_prm beta_p 
twoway (scatter avg_port_prm beta_p ) (line avg_port_prm beta_p ,sort)

save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q2/Weekly_Returns_P3.dta", replace
clear
