/*==============================================================================
part1	
	Description:
			In this part, we do necessary data cleaning for answering the question.
						
==============================================================================*/
clear

/* Get data of monthly stock prices, stock returns, market value of tradable shares*/
import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/TRD_Mnth.csv"

/* Construct a new column for lagged quarterly dates in the monthly stock price 
date - quarter1y */
gen month1 = monthly(trdmnt,"YM"), after(trdmnt)
format month1 %tm
gen quarter0 = qofd(dofm(month1))
gen quarter1 = quarter0-1 
format quarter0 %tq
format quarter1 %tq
rename ïstkcd stock_id

/*Calculate Stock Returns*/
gen TMktVa = 1000*msmvosd 	// The unit for Total MArket Value is 1000 CNY
gen NumOfShare = TMktVa/mclsprc 	// Get the number of shares in the market
gen Retnfstc = mclsprc/mopnprc-1 // Get stock returns
//drop b003000000 b004000000
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta"

clear

/* Get data of Total Assets and Total Liabilities*/
import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/FS_Combas.csv"
drop if typrep == "B"
gen date1 = date(accper,"YMD")
format date1 %td
gen quarter0 = qofd(date1)
format quarter0 %tq
gen month1 = mofd(date1)
format month1 %tm
rename ïstkcd stock_id
rename a001000000 Total_Assets
rename a002000000 Total_Liabs
rename a003000000 Total_Shahd_Equity
gen date = substr(accper,6,5)
drop if date == "01-01"
drop date
drop date1
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Balance_sheet.dta"

clear

/* Get data of EPS*/
import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/FI_T9.csv"
drop if typrep == "B"
rename f090101b EPS
rename ïstkcd stock_id
gen date1 = date(accper,"YMD")
format date1 %td
gen quarter1 = qofd(date1) // We use EPS of the lattest quarter that corresponds to quarter1 in stock_trading	
format quarter1 %tq
drop date1
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/EPS.dta"


clear

/* Get data of ROA and ROE*/
import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/FI_T5.csv"
rename ïstkcd stock_id
rename f050201b ROA
rename f050501b ROE
drop if typrep == "B"
gen date1 = date(accper,"YMD")
format date1 %td
gen quarter0 = qofd(date1)
format quarter0 %tq
drop date1
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/ROA ROE.dta"

clear

/* Get data of R&D Expense and Net profit
Exclude parent statements, exclude invalid data from annual Jan 1st*/
import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/FS_Comins.csv"
drop if typrep == "B"
gen date1 = date(accper,"YMD")
format date1 %td
gen quarter0 = qofd(date1)
format quarter0 %tq
rename ïstkcd stock_id
rename b001216000 RD_expense 
rename b002000000 Net_profit
gen date = substr(accper,6,5)
drop if date == "01-01"
drop date
drop date1
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Income_Statement.dta"

clear

/* Get data of Establishment Date and market type*/
import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/TRD_Co.csv"
gen date_estab = date(estbdt,"YMD")
format date_estab %td
gen date_list = date(listdt,"YMD")
format date_list %td
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Company Age.dta"

clear

/*Get single market typefor quarterly use*/
import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Market——type.csv"
rename ïstkcd stock_id
gen month1 = monthly(trdmnt,"YM")
format month1 %tm
gen quarter0 = qofd(dofm(month1))
format quarter0 %tq
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/market type.dta"

clear

/* Merge data for monthly use*/
use  "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta"
merge m:1 stock_id quarter0 using "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Income_Statement.dta"
drop _merge
merge m:1 stock_id quarter1 using "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/EPS.dta"
drop if missing(mclsprc)
drop _merge
merge m:1 stock_id quarter0 using "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Balance_sheet.dta"
drop _merge
drop if mopnprc ==.
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta", replace

clear

/* Merge data for quarterly use*/
use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Balance_sheet.dta"
merge 1:1 stock_id quarter0 using "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Income_Statement.dta"
drop _merge
merge 1:1 stock_id quarter0 using "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/ROA ROE.dta"
drop _merge
drop if accper == "1999-12-31"
merge m:1 stock_id month1 using "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/market type.dta"
drop _merge
drop if markettype == 8
drop if markettype == .
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Balance_sheet.dta", replace

/*==============================================================================
Part2
	Description:
			In this part, we answer Problem1
						
==============================================================================*/
/* question(a)*/
clear
	/***Derive the monthly P/E ratios, monthly P/B ratios***/
use  "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta"
gen Book_Value_PS = (Total_Assets-Total_Liabs)/NumOfShare // Calculate the value of book value per share
gen PE_Ratios = 3*mclsprc/EPS
gen PB_Ratios = mclsprc/Book_Value_PS
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta", replace

clear
	
	/***Derive the quarterly R&D expense/toatl asset ratios***/
use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Balance_sheet.dta"
gen RD_TotalAsset_Ratios = RD_expense/Total_Assets
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Balance_sheet.dta",replace

clear

	/***Derive the quarterly firm ages in the form of day，month and year***/
use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Company Age.dta"
gen age_in_day = date("2024-03-05","YMD")-date_estab
gen age_in_month = monthly("2024-03","YM")-monthly(substr(estbdt,1,7),"YM")
gen age_in_year = yearly("2024","Y")-yearly(substr(estbdt,1,4),"Y")
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Company Age.dta",replace
	

/* question(b)*/
/***First classify the data by market types (SME vs GEM)***/
clear

use  "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta"
drop if markettype == 2 | markettype == 8
recode markettype 1=0 4=0 64=0 16=1 32=1 ,gen(mkt_type)
tostring mkt_type,replace
replace mkt_type = "SME" if mkt_type == "0"
replace mkt_type = "GEM" if mkt_type == "1"
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta", replace

clear

use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Balance_sheet.dta"
drop if markettype == 2 | markettype == 8
recode markettype 1=0 4=0 64=0 16=1 32=1 ,gen(mkt_type)
tostring mkt_type,replace
replace mkt_type = "SME" if mkt_type == "0"
replace mkt_type = "GEM" if mkt_type == "1"
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Balance_sheet.dta",replace

clear

use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Company Age.dta"
drop if markettype == 2 | markettype == 8
recode markettype 1=0 4=0 64=0 16=1 32=1 ,gen(mkt_type)
tostring mkt_type,replace
replace mkt_type = "SME" if mkt_type == "0"
replace mkt_type = "GEM" if mkt_type == "1"
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Company Age.dta",replace

clear

ssc install outreg2
	
	/***Deal with the monthly data***/
use  "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta"
drop if Retnfstc==.| PE_Ratios==. | PB_Ratios==.
bysort mkt_type : summarize Retnfstc PE_Ratios PB_Ratios,detail 
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta", replace	

clear

	/***Deal with the quarterly data***/
use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Company Age.dta"
bysort mkt_type : summarize age_in_day age_in_month age_in_year,detail
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Company Age.dta",replace

clear

use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Balance_sheet.dta"
drop if ROA==. | ROE==.| RD_TotalAsset_Ratios==.
bysort mkt_type : summarize ROA ROE RD_TotalAsset_Ratios,detail
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Balance_sheet.dta",replace



/*==============================================================================
Part3
	Description:
			In this part, we answer Problem2
						
==============================================================================*/
clear
use  "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta"
bysort month1 mkt_type : egen med_PE = median (PE_Ratios) 
	
	/*** In this problem, we mainly research two stocks in SME board and GEM board respectively***/
gen med_PE_SME = med_PE if stock_id==000001
gen month_SME = month1 if stock_id==000001
gen med_PE_GEM = med_PE if stock_id==300001
gen month_GEM = month1 if stock_id==300001
format month_SME %tm
format month_GEM %tm
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading",replace

	/*** Next we successively take two different time scales ***/
	
	/*** Take monthly scale***/
tsset month_SME
twoway(line med_PE_SME month_SME)
tsset month_GEM
twoway(line med_PE_GEM month_GEM)

	/*** Take semi-annual scale to align with the most accurate EPS or P/E Ratios***/
gen m1 = substr(trdmnt,6,2)  if stock_id==000001
drop if m1== ""
destring m1,replace
keep if m1==3 | m1==9
gen semi_annual_SME = hofd(dofm(month1))
format semi_annual_SME %th
tsset semi_annual_SME
twoway(line med_PE_SME semi_annual_SME)

clear

use  "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Stock_Trading.dta"
gen m2 = substr(trdmnt,6,2)  if stock_id==300001
drop if m2== ""
destring m2,replace
keep if m2==3 | m2==9
gen semi_annual_GEM = hofd(dofm(month1))
format semi_annual_GEM %th
tsset semi_annual_GEM
twoway(line med_PE_GEM semi_annual_GEM)

clear



/*==============================================================================
Part3
	Description:
			In this part, we answer Problem2
						
==============================================================================*/
clear
import delimited "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Q3/AF_Actual_Q3.cvs"
rename ïsymbol symbol
gen year1 = yearly(substr(enddate,1,4),"Y")
format year1 %ty
drop if year1 < 2010
drop if year1>2020
egen x = count(year1),by(symbol)
drop if x!= 11
tsset symbol year1, yearly
gen growth_rate = totalrevenue/L.totalrevenue-1 
drop if growth_rate == .
drop x
egen y = count(year1),by(symbol)
drop if y!= 10
bysort year1: egen med_growth = median(growth_rate)
bysort year1: egen med_roe = median(roec)
egen N = count(symbol),by(year1)
save "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Q3/EPS Return.dta",replace

clear
	
	/*** We first deal with ROE ***/
use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Q3/EPS Return.dta"
drop if roec < med_roe
egen n = count(year1),by(symbol)
tsset symbol year1, yearly
gen x1 = 1 if roec >= med_roe & year == 2011
gen x2 = 1 if L.x1 == 1 & year1 == 2012
gen x3 = 1 if L.x2 == 1 & year1 == 2013
gen x4 = 1 if L.x3 == 1 & year1 == 2014
gen x5 = 1 if L.x4 == 1 & year1 == 2015
gen x6 = 1 if L.x5 == 1 & year1 == 2016
gen x7 = 1 if L.x6 == 1 & year1 == 2017
gen x8 = 1 if L.x7 == 1 & year1 == 2018
gen x9 = 1 if L.x8 == 1 & year1 == 2019
gen x10 = 1 if L.x9 == 1 & year1 == 2020

egen n1 = count(x1)
egen n2 = count(x2)
egen n3 = count(x3)
egen n4 = count(x4)
egen n5 = count(x5)
egen n6 = count(x6)
egen n7 = count(x7)
egen n8 = count(x8)
egen n9 = count(x9)
egen n10 = count(x10)

drop if n!=10
drop if symbol != 1

replace n=n1/N*100 if year1==2011
replace n=n2/N*100 if year1==2012
replace n=n3/N*100 if year1==2013
replace n=n4/N*100 if year1==2014
replace n=n5/N*100 if year1==2015
replace n=n6/N*100 if year1==2016
replace n=n7/N*100 if year1==2017
replace n=n8/N*100 if year1==2018
replace n=n9/N*100 if year1==2019
replace n=n10/N*100 if year1==2020

tsset year1
twoway(line n year1)

clear

	/*** We next deal with the growth rate ***/
use "/Users/benben/Desktop/大二下/FIN3080/ASSIGNMENT/HW1/Q3/EPS Return.dta"
drop if growth_rate < med_growth
egen n = count(year1),by(symbol)
tsset symbol year1, yearly
gen x1 = 1 if growth_rate >= med_roe & year == 2011
gen x2 = 1 if L.x1 == 1 & year1 == 2012
gen x3 = 1 if L.x2 == 1 & year1 == 2013
gen x4 = 1 if L.x3 == 1 & year1 == 2014
gen x5 = 1 if L.x4 == 1 & year1 == 2015
gen x6 = 1 if L.x5 == 1 & year1 == 2016
gen x7 = 1 if L.x6 == 1 & year1 == 2017
gen x8 = 1 if L.x7 == 1 & year1 == 2018
gen x9 = 1 if L.x8 == 1 & year1 == 2019
gen x10 = 1 if L.x9 == 1 & year1 == 2020

egen n1 = count(x1)
egen n2 = count(x2)
egen n3 = count(x3)
egen n4 = count(x4)
egen n5 = count(x5)
egen n6 = count(x6)
egen n7 = count(x7)
egen n8 = count(x8)
egen n9 = count(x9)
egen n10 = count(x10)

drop if n!=10
drop if symbol != 938

replace n=n1/N*100 if year1==2011
replace n=n2/N*100 if year1==2012
replace n=n3/N*100 if year1==2013
replace n=n4/N*100 if year1==2014
replace n=n5/N*100 if year1==2015
replace n=n6/N*100 if year1==2016
replace n=n7/N*100 if year1==2017
replace n=n8/N*100 if year1==2018
replace n=n9/N*100 if year1==2019
replace n=n10/N*100 if year1==2020

tsset year1
twoway(line n year1)

clear
