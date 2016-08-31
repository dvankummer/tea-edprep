******2014-15 STANDARD 2 ASEP ANALYSIS****;
**PART III. Clean the Principal Survey****;
****For FINAL POST DISTRIBUTION File******;
******************************************;
******************************************;

LIBNAME STAND2 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\SAS Files';



/*IMPORT THE EXCEL FILE*/

	PROC IMPORT OUT= Survey
			DATAFILE= "I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\TEA Excel Files\Postdistribution Survey Data with EPP List 2015.xlsx" 
	            DBMS=EXCEL REPLACE;
	     SHEET="POSTDISTRIBUTION DATA 2014-15"; 
	     GETNAMES=YES;
	RUN;
	
	
	
/* EXPLORE THE DATASET (n, variables, range of values)*/ 
 
	PROC CONTENTS DATA=Survey
		VARNUM;
	RUN;
	
	PROC SORT DATA=Survey;
	BY lbjid campus_num campus_name asep_id org_name_asep;
	RUN;
	
	PROC PRINT DATA=Survey N;
	RUN;
	
	PROC FREQ;
	RUN;
	
	
*****************************************************************************;
/*STEP 1:ELIMINATE INVALID SURVEYS*/
******************************************************************************;	

	
	PROC SORT DATA= STAND2.epps_all;
	BY asepid;
	RUN;

*Reformatt asep_id to retain leading zeros;

	DATA Survey0 (DROP=asep_id);
	SET Survey;
	    asepid=PUT(asep_id, z6.);
	RUN;
	
	PROC SORT DATA= WORK.Survey0;
	BY asepid;
	RUN;

	*Using the official list as a key, merge the predist to eliminate superfluous ISDs and EPPs;
	
	DATA survey2 (DROP=asep_id);
		MERGE STAND2.EPPS_ALL (in=epps143)
			   WORK.Survey0 (in=survey);
		BY asepid;
		IF epps143=1 AND survey=1;
	RUN;
		
	
/* 1a and 1b -ELIMINATE TEACHER NOT IN THEIR FIRST YEAR OF TEACHING PER BUSINESSRULE 1B*/
*Only first year teacherrs are eligible. So teacher has 0 years (first year) exp;
*Role id must = 87;

TITLE1 "Verification that all teachers are 1st in year of teaching";
	PROC FREQ DATA=Survey2;
	TABLES total_years_exper years_exper_district role_id;
	RUN;
TITLE1;


PROC SORT DATA=WORK.survey2;
BY person_survey_id;
RUN;



/* 1c-ELIMINATE BLANK SURVEYS*/

DATA WORK.survey3;
   SET WORK.survey2;
   BY person_survey_id; 
   last=last.person_survey_id ;
IF answer2 - answer40 = . THEN DELETE;

RUN;
	
	
/* 1d-REMOVE TEACHER DUPLICATE SURVEY*/

/* 1e-SAVE THE SURVEY FILE TO THE PERMANENT LIBRARY*/
DATA STAND2.SURVEY ;
	SET SURVEY3;
	RENAME org_name_asep=EPPSURVEY;
	
	IF last=1;
RUN;


/*Verify there are no duplicate surveys in this file now*/
PROC FREQ DATA=STAND2.SURVEY
ORDER=freq;
TABLES person_survey_id;
RUN;

PROC SORT DATA=STAND2.SURVEY;
BY lbjid;
RUN;


/* 1f-SAVE THE FILE IN EXCEL FORMAT*/

	PROC EXPORT DATA=STAND2.SURVEY
	OUTFILE= 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\Data Files\SURVEY_CLEAN n=14665.xlsx'
	DBMS = EXCEL REPLACE;
	RUN;





*****************************************************************************;
/*STEP 2:GENEARATE THE POST DISTRIBUTION FILE*/
******************************************************************************;


/* 2a-Merge the final Predistribution file with the Post Survey File*/
*THIS FILE CONTAINS THE INTIAL SAMPLE AND ELIGIBLE CERTS;

PROC SORT DATA=STAND2.FINAL_PREDISTRIBUTION;
BY lbjid;
RUN;


PROC SORT DATA=STAND2.SURVEY;
BY lbjid;
RUN;
	

PROC CONTENTS DATA=STAND2.SURVEY
VARNUM;
RUN;

/* 2b-Save the post distribution file to the permanent library
THIS FILE CONTAINS THE INTIAL SAMPLE AND ELIGIBLE CERTS*/

DATA STAND2.FINAL_POSTDISTRIBUTION
(DROP=org_route
route_type
asep_status1415
Region
Finished2015
ActionPlan
Notice
asepidD
asepid
district_num
district_name
campus_num
campus_name
prin_id
role_id
total_years_exper
years_exper_district
org_name_2
Undergraduate
Post_Bac
Alternative_Certification
For_Profit_ACP
survey_id
Last);

/* 2c-COMPUTE THE ESTIMATED RESPONSE RATE*/
	MERGE STAND2.FINAL_PREDISTRIBUTION (in=pre)
		  STAND2.SURVEY (in=post);
		  BY lbjid;
		  IF pre=1 and post=1;
		  responserate=(13941/20084)*100;
RUN;

PROC SORT;
BY lbjid;
RUN;


/* 2d- SAVE THE FILE IN EXCEL FORMAT*/

	PROC EXPORT DATA=STAND2.FINAL_POSTDISTRIBUTION
	OUTFILE= 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\Data Files\FINAL POSTDISTRIBUTION n=13941.xlsx'
	DBMS = EXCEL REPLACE;
	RUN;




*NOW OPEN '4 Standard 2 Analysis.sas' ;
