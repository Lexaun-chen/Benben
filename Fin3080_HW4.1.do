* Change the following path to your own path to this folder *
global Path_to_folder = "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW4.1"
* Set the following option off to enable uninterrupted screen outputs *
set more off

/*====================================================================================
Part1
	Description:
			In this part, we  process Individual stock return and market return data.
						
======================================================================================*/

	/* Get data of Indiviadual stock returns*/

insheet using "$Path_to_folder/raw_data/daily_stock_return1.csv", clear 
save"$Path_to_folder/Individual_stock_return1.dta",replace
insheet using "$Path_to_folder/raw_data/daily_stock_return2.csv", clear 
save"$Path_to_folder/Individual_stock_return2.dta",replace
insheet using "$Path_to_folder/raw_data/daily_stock_return3.csv", clear 
save"$Path_to_folder/Individual_stock_return3.dta",replace
insheet using "$Path_to_folder/raw_data/daily_stock_return4.csv", clear 
save"$Path_to_folder/Individual_stock_return4.dta",replace
insheet using "$Path_to_folder/raw_data/daily_stock_return5.csv", clear 
save"$Path_to_folder/Individual_stock_return5.dta",replace
insheet using "$Path_to_folder/raw_data/daily_stock_return6.csv", clear 
save"$Path_to_folder/Individual_stock_return6.dta",replace
insheet using "$Path_to_folder/raw_data/daily_stock_return7.csv", clear 
save"$Path_to_folder/Individual_stock_return7.dta",replace
insheet using "$Path_to_folder/raw_data/daily_stock_return8.csv", clear 
save"$Path_to_folder/Individual_stock_return8.dta",replace
insheet using "$Path_to_folder/raw_data/daily_stock_return9.csv", clear 
save"$Path_to_folder/Individual_stock_return9.dta",replace

use $Path_to_folder/Individual_stock_return1.dta ,clear

local filelist " 2 3 4 5 6 7 8 9"

foreach f of local filelist {
	append using "$Path_to_folder/Individual_stock_return`f'.dta"
}


rename stkcd stock_id
rename trddt raw_trading_date
rename dretnd daily_stock_return

gen trading_ymd = date(raw_trading_date,"YMD")
format trading_ymd %td
save"$Path_to_folder/Daily_individual_stock_return.dta"


	/* Get data of market stock returns*/
	
insheet using "$Path_to_folder/raw_data/daily_market_return.csv", clear 
rename trddt raw_trading_date
rename dretmdeq daily_market_return
rename markettype market

keep if market == 1 // Keep records for SSE A share market 
gen trading_ymd = date(raw_trading_date,"YMD")
format trading_ymd %td

save"$Path_to_folder/Daily_market_return.dta"

/*====================================================================================
Part2
	Description:
			In this part, we  process EPS data.
						
======================================================================================*/
insheet using "$Path_to_folder/raw_data/EPS.csv", clear 
rename stkcd stock_id
rename shortname_en short_name
rename accper raw_accounting_date
rename typrep statement_type
rename indcd industry_code
rename f090101b eps


	/* Exclude parent statements */
drop if statement_type == "B"
		
	/* Exclude ST and PT companies */
drop if strmatch( short_name, "*ST*")|strmatch( short_name, "*PT*")

	/* Exclude finance companies */
drop if strmatch( industry_code, "*J*")

	/* Convert original string dates to Year-Month-Day dates */
gen accounting_date_ymd = date(raw_accounting_date, "YMD")
format accounting_date_ymd %td  

	/* Keep obs at end of semi-annual only (in other words, the last obs for each stock in each semi-annual)*/
drop mod_half mod_annual
keep if mod(month(accounting_date_ymd), 6) == 0 
	
	/* Convert daily  dates to semi-year dates */
gen ending_date_yh = hofd(accounting_date_ymd)
format ending_date_yh %th

	/*Specify the data set as a company half-year panel */
xtset stock_id ending_date_yh 

	/* Eliminate the effect of cumulative EPS1 for the second half-year*/
replace eps = eps - l.eps if mod(month(accounting_date_ymd), 12) == 0 
drop if eps ==.

	/* Derive unexpected earnings(UE) */
gen ue = eps - l2.eps

	/*Derive standardize unexpected earnings(SUE), excluding missing data and outliers at 5% */
bysort stock_id: asrol ue, stat(sd) win(ending_date_yh 4)
gen sue = ue/ue_sd4

drop if ending_date_yh < yh(2016,1) 
drop if ue ==. |sue==.

	/* Exclude sue outliers at 5% levels */
summarize sue, detail
_pctile sue, p(5 95) 
local w1 = r(r1)
local w2 = r(r2)
keep if inrange(sue, `w1', `w2')



	/* Derive corresponding SUE deciles for each company by ending data of statistics */
bysort ending_date_yh: egen sue_decile = xtile(sue), p(10(10)90)

	/*Keep only the necessary data*/
keep stock_id ending_date_yh sue_decile

	/* Transform the data set into a firm-cross-sectional data set */
reshape wide sue_decile, i(stock_id) j(ending_date_yh)

save"$Path_to_folder/EPS.dta", replace

/*====================================================================================
Part3
	Description:
			In this part, we  process announcement data.
						
======================================================================================*/
insheet using "$Path_to_folder/raw_data/Announcement.csv", clear 
rename stkcd stock_id
rename stknme_en short_name
rename annodt announcement_date
rename accper raw_accounting_date
rename reptyp report_type 

	/* Keep only the interim and annual records */
keep if report_type == 2| report_type == 4

	/* Convert original string announcement daates to Year-Month-Day dates */
gen ann_date_ymd = date(announcement_date, "YMD")
format ann_date_ymd %td 

	/* Convert ending date of statistics into year-half dtaes */
gen accounting_date_ymd = date(raw_accounting_date, "YMD")
format accounting_date_ymd %td 
gen ending_date_yh = hofd(accounting_date_ymd)
format ending_date_yh %th

	/*Specify the data set as a company half-year panel */
xtset stock_id ending_date_yh 

	/*Keep only the necessary data*/
keep stock_id ending_date_yh ann_date_ymd

	/* Transform the data set into a firm-cross-sectional data set */
reshape wide ann_date_ymd, i(stock_id) j(ending_date_yh)

save"$Path_to_folder/Announcement.dta",replace

/*====================================================================================
Part4
	Description:
			In this part, we do data merging.
						
======================================================================================*/
use $Path_to_folder/Daily_individual_stock_return.dta, clear

merge m:1 trading_ymd using $Path_to_folder/Daily_market_return.dta
drop if _merge != 3
drop _merge
merge m:1 stock_id using $Path_to_folder/EPS.dta
drop if _merge != 3
drop _merge
merge m:1 stock_id using $Path_to_folder/Announcement.dta
drop if _merge != 3
drop _merge

rename daily_stock_return stock_ret
rename daily_market_return market_ret
drop raw_trading_date market 

save "$Path_to_folder/Panel_set.dta",replace

/*====================================================================================
Part5
	Description:
			In this part, we conduct event study.
						
======================================================================================*/
use $Path_to_folder/Panel_set.dta, clear
	
	/*Derive daily abnormal returns*/
gen stock_ab_ret = stock_ret - market_ret
sort stock_id trading_ymd
gen rowindex = _n
save "$Path_to_folder/Panel_set.dta",replace
	
	/* Derive event date index*/
local varlist " 112 113 114 115 116 117 118 119 120 121 122 123 124 125 "
foreach i of local varlist {
	use $Path_to_folder/Panel_set.dta, clear
	set more off
	keep stock_id stock_ab_ret sue_decile`i' ann_date_ymd`i' trading_ymd rowindex
	
	gen diff = trading_ymd - ann_date_ymd`i'
	gen abs_diff = abs(diff)
	bysort stock_id: egen abs_min = min(abs_diff)
	bysort stock_id: gen row_index = rowindex if abs_diff == abs_min
	bysort stock_id: egen min_row = max(row_index) 
	
	generate event_date = rowindex - min_row
	keep if event_date >= -60 & event_date <= 60
	
	keep event_date stock_ab_ret sue_decile`i'
	drop if sue_decile`i' ==. 
	
	bysort event_date sue_decile`i' : egen portfolio_ab_ret = mean(stock_ab_ret)
	bysort event_date sue_decile`i' : gen dup = cond(_N==1, 0,_n)
	drop if dup>1
	drop dup
	bysort sue_decile`i' (event_date): gen portfolio_car`i' = sum(portfolio_ab_ret)
	
	drop portfolio_ab_ret portfolio_ab_ret
	rename sue_decile`i' sue_decile
	save "$Path_to_folder/event`i'.dta",replace
}	


use $Path_to_folder/event112.dta ,clear

local Filelist " 113 114 115 116 117 118 119 120 121 122 123 124 125 "
foreach F of local Filelist {
	merge 1:1 sue_decile event_date using "$Path_to_folder/event`F'.dta"
	drop _merge
}
save "$Path_to_folder/Aggregation_event.dta",replace

use $Path_to_folder/Aggregation_event.dta, clear
local Varlist " 112 113 114 115 116 117 118 119 120 121 122 123 124 125 "
generate sum = 0
foreach V of local Varlist {
	replace sum = sum +portfolio_car`V'
}
gen mean_portfolio_car = sum/14

xtset sue_decile event_date
xtline mean_portfolio_car,overlay

save "$Path_to_folder/Aggregation_event.dta",replace







