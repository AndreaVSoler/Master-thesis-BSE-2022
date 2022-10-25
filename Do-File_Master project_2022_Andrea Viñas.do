/* -------------------------------------------------------------- */
/* MASTER THESIS CODE: SENEGAL FISH AGREEMENT                           */
/*                                                                */
/* Author: ERIC DISANTO, MICHEL DOUAIHY, KIMBERLY MASSA, ANDREA VIÑAS */                                    
/* Last update: June 2022 by Andrea Viñas                 */
/* -------------------------------------------------------------- */
********************************************************************************
*** WORKSPACE SET-UP ***
********************************************************************************

	clear all
    version 15
	set more off
	capture program drop _all
	capture log close                                                               
	set seed 1234

/* 
        To run this file on your system:
                Copy Paste the IF HOSTNAME If below, using your own hostname that you might find with the di code below
				Once you add an IF statement with your own hostname, it will work for all users listed.
				 
        
*/


	local hostname "`c(hostname)'"
	di "`c(hostname)'"
	
		
		if "`hostname'" == "DESKTOP-MRS09FP" {
		global dir "C:\Users\Andrea\Desktop\Master Thesis\Data" 
		
		}	

	cd $dir


//* aggregate the 12-13, 14, 15, 16, 17 Household members datasets *//

use "Children 2017.DTA"
append using "Children 2016.DTA"
append using "Children 2015.DTA"
append using "Children 2014.DTA"
append using "Children 2012-2013.DTA"


//* rename some variables *//

rename v007 Year
rename v024 Region
rename sseason Season
rename v190 Wealth_index_quintile
rename v191 Wealth_index_factor
rename b8 Age_Children //alive//
rename v001 Cluster
rename hw57 Kid_Anemialevel
rename v106 Mother_educlvl
rename hw56 Kid_Hemoglobin_adjusted
rename v012 Respondent_Age


//* generate dummy variable for Sex *//

gen Sex_child=1
replace Sex_child=0 if sh122g=1 

//* generate dummy variable for Taking iron pills during pregnancy *//

gen Iron_pills_pregnancy = m45
replace Iron_pills_pregnancy = 0 if m45 == 8

//* generate dummy variable for giving fish to child *//

gen Gave_child_fish= v414n
replace Gave_child_fish = 0 if v414n ==8

//* generate dummy variable for urban/rural *//

gen Urban_Rural = v025
replace Urban_Rural = 0 if v025==1
replace Urban_Rural = 1 if v025==2

//* Treatment and Post *//

gen Post=1
replace Post=0 if Year==2015
replace Post=0 if Year==2016
replace Post=0 if Year==2017

/* diourbiel==3, tambacounda==5, kaolack==6, kolda==10, matam==11, kaffrine==12, kedougou==13, sedhiou==14 */

gen Treatment=1
replace Treatment=0 if Region==3
replace Treatment=0 if Region==5
replace Treatment=0 if Region==6
replace Treatment=0 if Region==10
replace Treatment=0 if Region==11
replace Treatment=0 if Region==12
replace Treatment=0 if Region==13
replace Treatment=0 if Region==14

//*Cluster 2017*//

gen Cluster_2017 = Cluster if Cluster<215


**********************************************************
************** PARALLEL TREND ASSUMPTION *****************
**********************************************************

preserve
collapse (mean) Kid_Hemoglobin_adjusted, by(Treatment Year)
reshape wide Kid_Hemoglobin_adjusted, i(Year) j(Treatment)
graph twoway connect Kid_Hemoglobin_adjusted* Year, xline(2015)
restore


******************************************************************
************** FINAL DEP. VARIABLE: KID'S ANEMIA *****************
******************************************************************

//* MULTINOMIAL LOGIT MODEL WITH KIDS ANEMIA LEVEL + CLUSTERS + REGIONAL & TIME FE *//

/** LONG RUN: 2012-2017 **/

//without controls//
mlogit Kid_Anemialevel i.Treatment##i.Post i.Region i.Year, vce(cl Cluster_2017) 

outreg2 using main_mlogit_output.xls
outreg2 using main_mlogit_output.tex

//with controls//
mlogit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Wealth_index_quintile i.Gave_child_fish i.Region i.Year, vce(cl Cluster_2017)

outreg2 using main_mlogit_output.xls
outreg2 using main_mlogit_output.tex

// marginal effects //

margins, dydx(*)

outreg2 using margins_mlogit_output.tex


/** SHORT RUN: 2014-2015 **/

//without controls//
ologit Kid_Anemialevel i.Treatment##i.Post i.Region if Year==2014 | Year==2015, vce(cl Cluster_2017) 

outreg2 using main_ologit_output.xls
outreg2 using 1415main_ologit_output.tex

//with controls//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Wealth_index_quintile i.Gave_child_fish i.Region if Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using main_ologit_output.xls
outreg2 using 1415main_ologit_output.tex

// marginal effects //

margins, dydx(*)

outreg2 using margins_mlogit_output.tex


*************************************************************************************
***** ROBUSTNESS CHECKS LONG RUN v1: OLS, OPROBIT, W/O DAKAR WITHOUT CLUSTERING *****
*************************************************************************************

/** LONG RUN: 2012-2017 **/

//* OLS WITH HEMOGLOBINE LEVEL *//

//without controls//
reg Kid_Hemoglobin i.Treatment##i.Post i.Region i.Year, vce(cl Cluster_2017)

outreg2 using robustnesschecks1_output.tex

//with controls//
reg Kid_Hemoglobin i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Wealth_index_quintile i.Gave_child_fish i.Region i.Year, vce(cl Cluster_2017)

outreg2 using robustnesschecks1_output.tex

//* OPROBIT WITH ANEMIA LEVEL *//

oprobit Kid_Anemialevel i.Treatment##i.Post i.Region i.Year, vce(cl Cluster_2017)

outreg2 using robustnesschecks1_output.tex

oprobit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Wealth_index_quintile i.Gave_child_fish i.Region i.Year, vce(cl Cluster_2017)

outreg2 using robustnesschecks1_output.tex

/** SHORT RUN: 2014-2015 **/

//* OLS WITH HEMOGLOBINE LEVEL *//

//without controls//
reg Kid_Hemoglobin i.Treatment##i.Post i.Region if Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using robustnesschecks2_output.tex

//with controls//
reg Kid_Hemoglobin i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Wealth_index_quintile i.Gave_child_fish i.Region if Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using robustnesschecks2_output.tex


//* OPROBIT WITH ANEMIA LEVEL *//

oprobit Kid_Anemialevel i.Treatment##i.Post i.Region if Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using robustnesschecks2_output.tex

oprobit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Wealth_index_quintile i.Gave_child_fish i.Region if Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using robustnesschecks2_output.tex


/** WITHOUT DAKAR **/

//without controls//
ologit Kid_Anemialevel i.Treatment##i.Post i.Region i.Year if Region != 1, vce(cl Cluster_2017) 

outreg2 using robustnesschecks3.tex

//with controls//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Wealth_index_quintile i.Gave_child_fish i.Region i.Year if Region != 1, vce(cl Cluster_2017)

outreg2 using robustnesschecks3.tex


//without controls//
ologit Kid_Anemialevel i.Treatment##i.Post i.Region if Year==2014 | Year==2015 & Region != 1, vce(cl Cluster_2017) 

outreg2 using robustnesschecks4.tex

//with controls//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Wealth_index_quintile i.Gave_child_fish i.Region if Year==2014 | Year==2015 & Region != 1, vce(cl Cluster_2017)


outreg2 using robustnesschecks4.tex

******************************************************************
***** HETEROGENEITY: WEALTH QUINTILE, GENDER AND URBAN/RURAL *****
******************************************************************

/** LONG RUN: 2012-2017 **/

//* WEALTH INDEX QUINTILE *//

//poorest//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Region i.Year if Wealth_index_quintile==1, vce(cl Cluster_2017)

outreg2 using heterogeneity1.tex
outreg2 using heterogeneity.xls

//poorer//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Region i.Year if Wealth_index_quintile==2, vce(cl Cluster_2017) //NOT WORKING!!!//

outreg2 using heterogeneity1.tex
outreg2 using heterogeneity.xls

//middle//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Region i.Year if Wealth_index_quintile==3, vce(cl Cluster_2017)

outreg2 using heterogeneity1.tex
outreg2 using heterogeneity.xls

//richer//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Region i.Year if Wealth_index_quintile==4, vce(cl Cluster_2017)

outreg2 using heterogeneity1.tex
outreg2 using heterogeneity.xls

//richest//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Region i.Year if Wealth_index_quintile==5, vce(cl Cluster_2017) //NOT WORKING!!!//

outreg2 using heterogeneity1.tex
outreg2 using heterogeneity.xls

//* GENDER OF THE CHILD *//

//male//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region i.Year if Sex_child==0, vce(cl Cluster_2017)

outreg2 using heterogeneity1.tex
outreg2 using heterogeneity.xls

//female//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region i.Year if Sex_child==1, vce(cl Cluster_2017)

outreg2 using heterogeneity1.tex
outreg2 using heterogeneity.xls

//* URBAN/RURAL *//

//urban//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl  i.Iron_pills_pregnancy i.Sex_child i.Gave_child_fish i.Wealth_index_quintile i.Region i.Year if Urban_Rural==0, vce(cl Cluster_2017)

outreg2 using heterogeneity1.tex
outreg2 using heterogeneity.xls

//rural//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl  i.Iron_pills_pregnancy i.Sex_child i.Gave_child_fish i.Wealth_index_quintile i.Region i.Year if Urban_Rural==1, vce(cl Cluster_2017)

outreg2 using heterogeneity1.tex
outreg2 using heterogeneity.xls

//* MOTHER EDUCATIONAL LEVEL *//

//no education//
ologit Kid_Anemialevel i.Treatment##i.Post  i.Iron_pills_pregnancy i.Sex_child i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region i.Year if Mother_educlvl==0, vce(cl Cluster_2017)

outreg2 using heterogeneity.xls

//primary//
ologit Kid_Anemialevel i.Treatment##i.Post  i.Iron_pills_pregnancy i.Sex_child i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region i.Year if Mother_educlvl==1, vce(cl Cluster_2017)

outreg2 using heterogeneity.xls

//secondary//
ologit Kid_Anemialevel i.Treatment##i.Post  i.Iron_pills_pregnancy i.Sex_child i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region i.Year if Mother_educlvl==2, vce(cl Cluster_2017)

outreg2 using heterogeneity.xls

//higher//
ologit Kid_Anemialevel i.Treatment##i.Post  i.Iron_pills_pregnancy i.Sex_child i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region i.Year if Mother_educlvl==3, vce(cl Cluster_2017) //NOT WORKING!!!//

outreg2 using heterogeneity.xls

/** SHORT RUN: 2014-2015 **/

//* WEALTH INDEX QUINTILE *//

//poorest//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Region if Wealth_index_quintile==1 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls
outreg2 using heterogeneityshortrun.tex

//poorer//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Region if Wealth_index_quintile==2 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls
outreg2 using heterogeneityshortrun.tex

//middle//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Region if Wealth_index_quintile==3 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls
outreg2 using heterogeneityshortrun.tex

//richer//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Region if Wealth_index_quintile==4 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls
outreg2 using heterogeneityshortrun.tex

//richest//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl i.Sex_child  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Region if Wealth_index_quintile==5 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls
outreg2 using heterogeneityshortrun.tex

//* GENDER OF THE CHILD *//

//male//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region if Sex_child==0 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls

//female//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl  i.Iron_pills_pregnancy i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region if Sex_child==1 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls

//* URBAN/RURAL *//

//urban//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl  i.Iron_pills_pregnancy i.Sex_child i.Gave_child_fish i.Wealth_index_quintile i.Region if Urban_Rural==0 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls

//rural//
ologit Kid_Anemialevel i.Treatment##i.Post i.Mother_educlvl  i.Iron_pills_pregnancy i.Sex_child i.Gave_child_fish i.Wealth_index_quintile i.Region if Urban_Rural==1 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls

//* MOTHER EDUCATIONAL LEVEL *//

//no education//
ologit Kid_Anemialevel i.Treatment##i.Post  i.Iron_pills_pregnancy i.Sex_child i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region if Mother_educlvl==0 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls

//primary//
ologit Kid_Anemialevel i.Treatment##i.Post  i.Iron_pills_pregnancy i.Sex_child i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region if Mother_educlvl==1 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls

//secondary//
ologit Kid_Anemialevel i.Treatment##i.Post  i.Iron_pills_pregnancy i.Sex_child i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region if Mother_educlvl==2 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using heterogeneityshortrun.xls

//higher//
ologit Kid_Anemialevel i.Treatment##i.Post  i.Iron_pills_pregnancy i.Sex_child i.Urban_Rural i.Gave_child_fish i.Wealth_index_quintile i.Region if Mother_educlvl==3 & Year==2014 | Year==2015, vce(cl Cluster_2017)

outreg2 using "heterogeneityshortrun.xls"
