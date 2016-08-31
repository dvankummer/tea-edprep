******2014-15 STANDARD 2 ASEP ANALYSIS****;
**PART IV. SBEC Standard 2 Analysis*******;
******************************************;
******************************************;
******************************************;

LIBNAME STAND2 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\SAS Files';

	
/* EXPLORE THE DATASET (n, variables, range of values)*/ 
 
PROC MEANS DATA=STAND2.FINAL_POSTDISTRIBUTION;
VAR answer2-answer40;
RUN;



/* Format the data set and compute first and last variables)*/ 

PROC SORT DATA=STAND2.FINAL_POSTDISTRIBUTION ;
BY asep_id1;
RUN;



*****************************************************************************;
/*STEP 1:Clean the dataset to prepare for analysis*/
******************************************************************************;

DATA WORK.asep2;
SET STAND2.FINAL_POSTDISTRIBUTION;



BY asep_id1;
first=first.asep_id1;
last=last.asep_id1;

Region3 = "characterlengthofregion";

/*Recode the regions from numvars to char*/
IF Region1 = 1 THEN Region3 = "Edinburg";
IF Region1 = 2 THEN Region3 = "Corpus Christi";
IF Region1 = 3 THEN Region3 = "Victoria";
IF Region1 = 4 THEN Region3 = "Houston";
IF Region1 = 5 THEN Region3 = "Beaumont";

IF Region1 = 6 THEN Region3 = "Huntsville";
IF Region1 = 7 THEN Region3 = "Kilgore";
IF Region1 = 8 THEN Region3 = "Mount Pleasant";
IF Region1 = 9 THEN Region3 = "Wichita Falls";
IF Region1 = 10 THEN Region3 = "Richardson";

IF Region1 = 11 THEN Region3 = "Richardson";
IF Region1 = 12 THEN Region3 = "Waco";
IF Region1 = 13 THEN Region3 = "Austin";
IF Region1 = 14 THEN Region3 = "Abilene";
IF Region1 = 15 THEN Region3 = "San Angelo";

IF Region1 = 16 THEN Region3 = "Amarillo";
IF Region1 = 17 THEN Region3 = "Lubbock";
IF Region1 = 18 THEN Region3 = "Midland";
IF Region1 = 19 THEN Region3 = "El Paso";
IF Region1 = 20 THEN Region3 = "San Antonio";



/*STEP 1a-Use an array to recode survey responses from 1-4 to 0-3*/ 

ARRAY ans[39] answer2-answer40;
ARRAY q [39] q2-q40;
DO i = 1 to 39;
	IF ans(i) = 1 THEN q(i) = 0;
	ELSE IF ans(i) = 2 THEN q(i) = 1;
	ELSE IF ans(i) = 3 THEN q(i) = 2;
	ELSE IF ans(i) = 4 THEN q(i) = 3;
	ELSE q(i) = .;
END;
DROP i;


*****************************************************************************;
/*STEP 2-Compute survey sum by domain and survey total*/
******************************************************************************;
	CE=SUM(q4,q5,q6,q7,q8);
	INS=SUM(q9,q10,q11,q12,q13,q14,q15,q16);
	SWD=SUM(q18,q19,q20,q21,q22,q23,q24);
	ELL=SUM(q26,q27,q28,q29,q30);
	TI=SUM(q31,q32,q33,q34);
	TU=SUM(q35,q36,q37,q38);
	
	surveytotal=SUM(CE,INS,SWD, ELL, TI, TU);
	surveytotal_NoSWD_ELL =.;
	surveytotal_NoSWD = .;	
	surveytotal_NoELL = .;
	
	surveytotal_2higherCE =0;
	surveytotal_2higherINS=0;
	surveytotal_2higherSWD=0;
	surveytotal_2higherELL=0;
	surveytotal_2higherTI=0;
	surveytotal_2higherTU=0;
	surveytotal_2higher=0;


/*2a-Compute teacher domain totals for meeting standard*/

	CE=SUM(q4,q5,q6,q7,q8);
	INS=SUM(q9,q10,q11,q12,q13,q14,q15,q16);
	SWD=SUM(q18,q19,q20,q21,q22,q23,q24);
	ELL=SUM(q26,q27,q28,q29,q30);
	TI=SUM(q31,q32,q33,q34);
	TU=SUM(q35,q36,q37,q38);

	IF CE	>= (2*5) THEN surveytotal_2higherCE = 1;
	IF INS	>= (2*8) THEN surveytotal_2higherINS = 1;
	IF TI	>= (2*4) THEN surveytotal_2higherTI = 1;
	IF TU	>= (2*4) THEN surveytotal_2higherTU = 1;
	
/*ONLY 11419 TEACHERS HAD SWD DOMAIN, ONLY 10,700 HAD ELL DOMAIN
BECAUSE OF THIS THE DENOMINATOR IS NOT 13941. ADJUST ACCORDINGLY*/
	
	IF SWD OR ELL NE . THEN DO;

		IF SWD >= (2*7) THEN surveytotal_2higherSWD =1;
		IF SWD = . THEN surveytotal_2higherSWD = .;
		
		IF ELL >= (2*5) THEN surveytotal_2higherELL = 1;
		IF ELL = . THEN surveytotal_2higherELL = .;
		
	END;
	

/*2b-Compute survey totals*/


	IF ELL = . AND  SWD = . THEN surveytotal_NoSWD_ELL=(CE) + (INS) +(TI) + (TU);
	ELSE IF SWD = . THEN surveytotal_NoSWD=(CE) + (INS) + (ELL) + (TI) + (TU);
	ELSE IF ELL=. THEN surveytotal_NoELL=(CE) + (INS) + (SWD) + (TI) + (TU);




/*2c-Compute teacher totals for meeting standard*/


	IF  (ELL AND SWD NE .) AND surveytotal >= 66 
	THEN surveytotal_2higher=1;

	IF surveytotal_NoSWD_ELL >= 42
	THEN surveytotal_2higher =1;

	IF surveytotal_NoSWD >= 52
	THEN surveytotal_2higher =1;

	IF surveytotal_NoELL >= 56
	THEN  surveytotal_2higher =1;

	IF surveytotal_2higher = . THEN surveytotal_2higher=0;	

RUN;



/*Examine the descriptive statistics of the survey totals*/ 

PROC MEANS DATA=WORK.SBEC N MEAN SUM MAX MIN;
VAR surveytotal
	surveytotal_NoSWD_ELL
	surveytotal_NoSWD	
	surveytotal_NoELL
	
	surveytotal_2higherCE 
	surveytotal_2higherINS
	surveytotal_2higherSWD
	surveytotal_2higherELL
	surveytotal_2higherTI
	surveytotal_2higherTU
	surveytotal_2higher
	CERTCOUNT;

RUN;


/*2d-Export the teacher-level file to MS Excel*/ 

	PROC EXPORT DATA=WORK.asep2
	OUTFILE= 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\Data Files\2014-15 Standard 2 Analysis n=13941.xlsx'
	DBMS = EXCEL REPLACE;
	RUN;


****************************************************************************************;
/*STEP 3-Aggregate teacher totals to the EPP Level and compute totals by cut score*/
****************************************************************************************;

/*3a: Invoke SQL to create an EPP-level file*/

PROC SQL;
CREATE TABLE WORK.PREPAREDEPP AS
	SELECT lbjid, asep_id1 AS asep_id, org_name_asep1 AS org_name, Region3 AS region, org_route1 AS route_type, route_type1 AS route_subtype, 
			COUNT(*) AS N_surveys, 
			SUM(surveytotal_2higher) AS prepared,
			AVG(surveytotal_2higher) AS pctprepared, 
			AVG(surveytotal_2higherCE) AS pctpreparedCE,
			AVG(surveytotal_2higherINS) AS pctpreparedINS,
			AVG(surveytotal_2higherSWD) AS pctpreparedSWD,
			AVG(surveytotal_2higherELL) AS pctpreparedELL,
			AVG(surveytotal_2higherTI) AS pctpreparedTI,
			AVG(surveytotal_2higherTU) AS pctpreparedTU,
			SUM(CERTCOUNT) AS total_certs, 
				SUM(Bilingual) AS BilingualEd,
				SUM(CompSci) AS CompSci,
				SUM(English) AS English,
				SUM(Fine_Arts) AS FineArts,
				SUM(Foreign)AS ForeignLanguage,
				SUM(Generaly)AS GernalELM,
				SUM(HealthPE)AS HealthPE,
				SUM(Math)AS Math,
				SUM(OtherR)AS Other,
				SUM(Professional)AS Professional,
				SUM(Science)AS Science,
				SUM(Soc_Studies)AS SocStud,
				SUM(SpEd) AS SPED,
				SUM(VocEd)AS Vocational
	FROM WORK.asep2
	GROUP BY  asep_id1;
QUIT;


/*Remove the duplicate EPP records*/ 
DATA preparedEPP (DROP=lbjid);

	SET preparedEPP;
	BY asep_id;
	last=last.asep_id;
	IF last=1;
/*Compute small n exception variables*/ 
	samplesizeless_10 = 0;
	samplesizeless_20 = 0;

	IF N_surveys <= 10 THEN samplesizeless_10 = 1;
	 ELSE samplesizeless_10 = 0 ;
	IF N_surveys <= 20 THEN samplesizeless_20 = 1;
		ELSE samplesizeless_20 = 0 ;
RUN;



/*STEP 3b-Compute cut scores*/
*Save the SurveyAnalysis file to the permanent library;
DATA STAND2.SurveyAnalysis (DROP=last);
SET preparedEPP;

	metSt2_noCI_70cs = 0;
	metSt2_noCI_75cs = 0;
	metSt2_noCI_80cs = 0;
	metSt2_noCI_85cs = 0;
	metSt2_noCI_90cs = 0;
	
		*70;
		IF pctprepared >= .70  THEN metSt2_noCI_70cs=1;
		*75;
		IF pctprepared >= .75 THEN metSt2_noCI_75cs=1;
		*80;
		IF pctprepared >= .80 THEN metSt2_noCI_80cs=1;
		*85;
		IF pctprepared >= .85 THEN metSt2_noCI_85cs=1;
		*90;
		IF pctprepared >= .90 THEN metSt2_noCI_90cs=1;
	
	
	/* SURVEYS MORE THAN 10*/
	IF samplesizeless_10 = 0 THEN DO;
	
		*70;
		IF pctprepared >= .70 THEN metSt2_noCI_70cs=1;
		*75;
		IF pctprepared >= .75  THEN metSt2_noCI_75cs=1;
		*80;
		IF pctprepared >= .80  THEN metSt2_noCI_80cs=1;
		*85;
		IF pctprepared >= .85 THEN metSt2_noCI_85cs=1;
		*90;
		IF pctprepared >= .90 THEN metSt2_noCI_90cs=1;
	END; 
	
	/* SURVEYS MORE THAN 20*/
	
		IF samplesizeless_20 = 0 THEN DO;
		*70;
		IF pctprepared >= .70 THEN metSt2_noCI_70cs=1;
		*75;
		IF pctprepared >= .75 THEN metSt2_noCI_75cs=1;
		*80;
		IF pctprepared >= .80 THEN metSt2_noCI_75cs=1;
		*85;
		IF pctprepared >= .85 THEN metSt2_noCI_85cs=1;
		*90;
		IF pctprepared >= .90 THEN metSt2_noCI_90cs=1;
	END; 

RUN;


/*STEP 3c-Output cutscores for <10 AND <20s EPPs*/
DATA METALL;
SET STAND2.SurveyAnalysis;

RUN;


TITLE1 "ALL EPPS 129";

PROC MEANS DATA=METALL N MEAN SUM MAX MIN ;
VAR N_Surveys 
metSt2_noCI_70cs 
metSt2_noCI_75cs 
metSt2_noCI_80cs 
metSt2_noCI_85cs 
metSt2_noCI_90cs;
RUN;
TITLE1;

/************************/

DATA MET10MORE;
SET STAND2.SurveyAnalysis;
IF samplesizeless_10 = 0 ;
RUN;


TITLE2 "EPPS SURVEYS > 10 n=105";

PROC MEANS DATA=MET10MORE N MEAN SUM MAX MIN ;
VAR N_Surveys 
metSt2_noCI_70cs 
metSt2_noCI_75cs 
metSt2_noCI_80cs 
metSt2_noCI_85cs 
metSt2_noCI_90cs;
RUN;
TITLE2;

/************************/

DATA MET20MORE;
SET STAND2.SurveyAnalysis;
IF samplesizeless_20 = 0 ;
RUN;


TITLE3 "EPPS SURVEYS > 20 n=89";

PROC MEANS DATA=MET20MORE N MEAN SUM MAX MIN ;
VAR N_Surveys 
metSt2_noCI_70cs 
metSt2_noCI_75cs 
metSt2_noCI_80cs 
metSt2_noCI_85cs 
metSt2_noCI_90cs;
RUN;
TITLE3;





************************************************************;
/*STEP 4-Aggregate totals to the State level*/
************************************************************;


/*4a: Invoke SQL to create an state-level file*/
PROC SQL;
CREATE TABLE STATE_SUMMARY AS
	SELECT SUM(N_surveys) AS N,
			SUM(prepared) AS STATE_prepared,
			AVG(pctprepared) AS STATE_pctprepared, 
			AVG(metSt2_noCI_70cs)AS STATE_pctprepared_70CS,
			AVG(metSt2_noCI_75cs)AS STATE_pctprepared_75CS,
			AVG(metSt2_noCI_80cs)AS STATE_pctprepared_80CS,
			AVG(metSt2_noCI_85cs)AS STATE_pctprepared_85CS,
			AVG(metSt2_noCI_90cs)AS STATE_pctprepared_90CS,
			AVG(pctpreparedCE) AS STATE_pctpreparedCE,
			AVG(pctpreparedINS) AS STATE_pctpreparedINS,
			AVG(pctpreparedSWD) AS STATE_pctpreparedSWD,
			AVG(pctpreparedELL) AS STATE_pctpreparedELL,
			AVG(pctpreparedTI) AS STATE_pctpreparedTI,
			AVG(pctpreparedTU) AS STATE_pctpreparedTU,
			SUM(total_certs) AS STATE_total_certs, 
				SUM(BilingualEd) AS STATE_BilingualEd,
				SUM(CompSci) AS STATE_CompSci,
				SUM(English) AS STATE_English,
				SUM(FineArts) AS STATE_FineArts,
				SUM(ForeignLanguage)AS STATE_ForeignLanguage,
				SUM(GernalELM)AS STATE_GernalELM,
				SUM(HealthPE)AS STATE_HealthPE,
				SUM(Math)AS STATE_Math,
				SUM(Other)AS STATE_Other,
				SUM(Professional)AS STATE_Profesional,
				SUM(Science)AS STATE_Science,
				SUM(SocStud)AS STATE_SocStud,
				SUM(SPED) AS STATE_SPED,
				SUM(Vocational)AS STATE_Vocational
	FROM STAND2.SurveyAnalysis;
QUIT;



/*4b-Merge the state summary with the EPP level file*/



PROC SORT DATA = STAND2.SurveyAnalysis; 
BY org_name;
RUN;

*Save the 1415_Standard2 file to the permanent library;

	DATA STAND2.Standard2_1415;
		MERGE STAND2.SurveyAnalysis
			  WORK.STATE_SUMMARY;
	RUN;


/* Save the file in excel*/


	PROC EXPORT DATA=STAND2.Standard2_1415
	OUTFILE= 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\Data Files\2014-15 Standard 2 Analysis n=129.xlsx'
	DBMS = EXCEL REPLACE;
	RUN;
	
	
*FIN;
			