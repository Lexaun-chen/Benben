/*==============================================================================
Part1
	Description:
			In this part, we import the raw data of Problem1.
						
==============================================================================*/
clear

	/* Get data of daily closing returns of CSI300*/
import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q1/Closing_Index.csv"
rename ïindexcd index_code
gen Trddt = date(trddt,"YMD")
format Trddt %td

save"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q1/Monthly_returns_CSI300.dta"

clear

/*=========================================================================================================
Part2
	Description:
			In this part, we answer for part(a). 
			We manually derive monthly CSI 300 index returns and provide deatiled summary statistics.
						
===========================================================================================================*/
clear

/*** Derive monthly CSI300 index returns***/
use"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q1/Monthly_returns_CSI300.dta"

gen year = substr(trddt,1,4)
gen month = substr(trddt,6,2)
gen date = substr(trddt,9,2)
destring year month date, replace

	/* Remain only data from the last trading date of each month*/
bysort index_code year month: egen max_day = max(date)
gen last_day = mdy(month, max_day, year)
format last_day %td
keep if Trddt == last_day

	/* Derive the monthly CSI300 index returns*/
gen Trdmt = mofd(Trddt)
format Trdmt %tm
tsset index_code Trdmt, monthly
gen Month_Rt = clsindex/L.clsindex -1 if trddt != "2003-12-31"
drop if Month_Rt ==.

	/* Derive the summary statistics for monthly CSI300 index returns*/
summarize Month_Rt,detail 

save"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q1/Monthly_returns_CSI300.dta", replace

clear

/*==================================================================================================================================
Part3
	Description:
			In this part, we answer for part(b). 
			We plot a histogram which is granular enough for describing the probability density function of CSI 300 monthly returns.
						
===================================================================================================================================*/
clear 

use"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q1/Monthly_returns_CSI300.dta"

histogram Month_Rt, fraction bin(100) normal 

save"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q1/Monthly_returns_CSI300.dta", replace

clear

/*==================================================================================================================================
Part3
	Description:
			In this part, we answer for part(c). 
			We test whether the  probability density function of CSI 300 monthly returns follows a normal distribution.
						
===================================================================================================================================*/
clear

use"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q1/Monthly_returns_CSI300.dta"

/*From summary statistics*/
	/*We generate 3310 observations following normal distribution with same mean and sd with Month——Rt.*/
set obs 3310
local mean = 0.0080958
local std_dev = 0.0821718
gen normal_data_custom = `mean' + `std_dev' * rnormal()
summarize normal_data_custom,d

/* From normality testing*/
swilk Month_Rt
sktest Month_Rt

save"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q1/Monthly_returns_CSI300.dta", replace



save"/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW3/Q1/Monthly_returns_CSI300.dta", replace
