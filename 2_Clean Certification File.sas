******2014-15 STANDARD 2 ASEP ANALYSIS****;
**PART II. Clean the certification file**;
******************************************;
******************************************;

LIBNAME STAND2 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\SAS Files';


/*IMPORT THE EXCEL FILE*/

	PROC IMPORT OUT= Certification
			DATAFILE= "I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\TEA Excel Files\Certification Data with EPP List 2015.xlsx" 
	            DBMS=EXCEL REPLACE;
	     SHEET="CERTIFICATION DATA 2014-15"; 
	     GETNAMES=YES;
	RUN;
	
	
	DATA Certification;
	SET Certification;
		asepidD = INPUT(asep_id, 6.);
	    asepid=PUT(asepidD, z6.);
	RUN;

/* EXPLORE THE DATASET (n, variables, range of values)*/ 
 
	PROC CONTENTS DATA=Certification;
	RUN;
	
	PROC SORT DATA=Certification;
	BY lbjid asep_id cert_area cert_effective;
	RUN;
	
	PROC PRINT DATA=Certification;
	VAR lbjid asep_id org_name_asep cert_area cert_effective;
	RUN; 


*COMPARE AGAINST THE OFFICIAL LIST OF 2014-15 EPPs (n=143);

	
	DATA STAND2.epps_all;
	SET STAND2.epps_all;
		asepidD = INPUT(asep_id, 6.);
	    asepid=PUT(asepidD, z6.);
	RUN;
	
	
	PROC SORT DATA= STAND2.epps_all;
	BY asepid;
	RUN;
	
	
	PROC SORT DATA= WORK.Certification;
	BY asepid;
	RUN;
	
*Using the official list as a key, merge the predist to eliminate superfluous ISDs and EPPs;
	DATA EPPSCERT;
		MERGE STAND2.epps_all (in=epp143)
			  WORK.Certification (in=certs);
		BY asepid;
		First = first.asepid;
		Last =  last.asepid;
		IF epp143=1 AND certs=1;
	RUN;
	



	
TITLE2 "2015-15 EPPs in Predistribution File";
	PROC PRINT DATA = EPPSCERT N;
	VAR asepid org_name_asep;
		WHERE First = 1;
	RUN;
TITLE2;
*134 of 143 EPPS are present in the predistribution file;	
	

	
*Determine the 9 EPPs that are not in the 2014-15 Predistribution file sample;

DATA Dregs;
 MERGE WORK.EPPSCERT(in=sample)
	   STAND2.epps_all(in=onefortythree);
	  BY asepid;
	  IF onefortythree=1 AND sample=0;
	 RUN;
	
TITLE3 "EPPS Without Survey Data";
	PROC PRINT DATA = Dregs N;
	 VAR asepid org_name_asep;
	RUN;
TITLE3;

	
*****************************************************************************;
/*1: IDENTIFY TEACHER CANDIDATES WITH ELIGIBLE CERTIFICATIONS
	PER BUSINESS RULE 1A: A teacher must have been certified within the past 5 years,
	and no later than than the prior academic year*/
******************************************************************************;

	DATA cert;
		SET EPPSCERT;
		 earliest= MDY(09,01,2009);
		 latest= MDY(08,31,2014);		
		 cert_age = YRDIF(cert_effective,latest ,'actual');
		
		IF cert_effective <= MDY(08,31,2014) THEN certeligible_gr1yr= 1;
			ELSE certeligible_gr1yr=0;
		
/* 1a-IDENTIFY TEACHERS CERTIFIED WITHIN THE PAST 6 YEAR (5 years before 2014-15)*/
	
		IF cert_effective GT MDY(09,01,2009) THEN certeligible_6yr=1;
			ELSE certeligible_6yr=0;
		
/* 1b-IDENTIFY TEACHERS CERTIFIED NO LATER THAN THE PRIOR YEAR*/
			
		IF cert_effective <= MDY(08,31,2014) THEN certeligible_gr1yr= 1;
			ELSE certeligible_gr1yr=0;

/* 1c-CREATE A FILTER WITH CERT DATE BETWEEN 9/1/2009 and 8/31/2014*/
			
		IF MDY(09,01,2009) < cert_effective <= MDY(08,31,2014) THEN CERT_ELIGIBLE = 1;
			ELSE CERT_ELIGIBLE=0;
			
		IF certeligible_6yr = 1 AND certeligible_gr1yr =1 THEN ELIG_CHECK = 1;
			ELSE ELIG_CHECK=0;
	RUN;


TITLE1 "Obtained certification after 2009";
	PROC FREQ DATA=cert;
		TABLES certeligible_6yr ;
	RUN;
TITLE1;


TITLE2 "Obtained certification in prior academic year (before 2015-16)";
	PROC FREQ DATA=cert;
		TABLES certeligible_gr1yr;
	RUN;
TITLE2;


TITLE3 "Teachers with eligible certifications (between 2009-10 and 2013-14)";
	PROC FREQ DATA=cert;
		TABLES CERT_ELIGIBLE ELIG_CHECK ;
	RUN;
TITLE3;


/* 1d-REMOVE TEACHERS WITH CERT TYPES THAT ARE NOT STANDARD OR PROBATIONARY*/

PROC FREQ DATA= WORK.cert;
	TABLES cert_type*CERT_ELIGIBLE /MISSING NOCOL NOROW NOPERCENT ;
RUN;

*RECODE cert_type values for ease of selection;
DATA WORK.cert;
  SET WORK.cert;
  certtype_num = .;
  IF cert_type='Emergency' THEN  certtype_num = 1;
  IF cert_type='Emergency Certified' THEN  certtype_num = 2;
  IF cert_type='Non-renewable' THEN  certtype_num = 3;
  IF cert_type='One Year' THEN  certtype_num = 4;
  IF cert_type='Probationary' THEN  certtype_num = 5;
  IF cert_type='Probationary Extension' THEN  certtype_num = 6;
  IF cert_type='Probationary Second Extension ' THEN  certtype_num = 7;
  IF cert_type='Standard' THEN  certtype_num = 8;
  IF cert_type='Standard Paraprofessional' THEN  certtype_num = 9;
  IF cert_type='Standard Professional' THEN  certtype_num = 10;
  IF cert_type='Visiting International Teacher' THEN  certtype_num = 11;
  
RUN;


PROC SORT DATA=WORK.cert;
BY cert_type;
RUN;

PROC PRINT DATA=WORK.cert;
var cert_type certtype_num;
RUN;


	DATA certelig;
		SET WORK.cert (DROP=org_name_2 Undergraduate Post_Bac Alternative_Certification For_Profit_ACP );
			IF CERT_ELIGIBLE = 1 ;
			IF certtype_num = 5 OR
			    certtype_num = 6 OR
				certtype_num = 7 OR
				certtype_num = 8 OR
				certtype_num = 9 OR
				certtype_num = 10;

/*	Create an Array of Certification Variables*/
				
		Bilingual=.;
		CompSci=. ;
		English =.; 
		Fine_Arts =.;
		Foreign =.;
		Generaly=.;
		HealthPE=.;
		Math=.;
		OtherR =.;
		Professional=.;
		Science=.;
		Soc_Studies=.;
		SpEd =.;
		VocEd=.;
RUN;
	
PROC FREQ DATA= certelig;
	TABLES cert_type*CERT_ELIGIBLE org_route /MISSING NOCOL NOROW NOPERCENT;
RUN;


PROC SORT DATA=certelig;
BY lbjid cert_effective;
RUN;


**************************************************************************************
/* 2-.	Identify eligible certifications for teachers with multiple certifications 
per Business Rule 1B: For teachers who earn certificates from multiple EPPs,
 the most recent EPP associated with the teacher will be held accountable*/
**************************************************************************************


/* 2a Invoke SQL and use the MAX function*/
*This might take a while...;
PROC SQL;
	CREATE TABLE work.eligcerts AS
	SELECT *, count(*) AS CERTCOUNT
	FROM work.certelig S
	WHERE cert_effective=(
		SELECT MAX(cert_effective)   
		FROM work.certelig
		WHERE lbjid=S.lbjid) 
		GROUP BY lbjid;  
QUIT;



TITLE4 "Teachers and EPPs with the Most Recent Certs";
PROC PRINT DATA=work.eligcerts;
	VAR lbjid asep_id org_name_asep cert_id cert_area cert_effective CERTCOUNT;
	FORMAT cert_effective WORDDATE20.;
RUN;
TITLE4;



DATA WORK.eligcerts2 (KEEP=lbjid
				asep_id
				org_name_asep
				org_route
				route_type
				cert_area
				cert_area_mod
				cert_desc
				cert_grade
				cert_field_cd
				cert_id
				cert_effective
				cert_day
				cert_month
				cert_year
				CERT_ELIGIBLE
				cert_type
				certtype_num
				CERTCOUNT
				Bilingual
				CompSci
				English 
				Fine_Arts
				Foreign
				Generaly
				HealthPE
				Math
				OtherR
				Professional
				Science
				Soc_Studies
				SpEd
				VocEd);	
SET work.eligcerts;				
RUN;




PROC CONTENTS
VARNUM;
RUN;


PROC SQL;
	CREATE TABLE work.eligcert2 AS
	SELECT lbjid,
		asep_id,
		org_name_asep,
		org_route,
		route_type,
		cert_area,
		cert_area_mod,
		cert_desc,
		cert_grade,
		cert_field_cd,
		cert_id,
		cert_effective,
		cert_day,
		cert_month,
		cert_year,
		CERT_ELIGIBLE,
		cert_type,
		certtype_num,
		CERTCOUNT,
		Bilingual,
		CompSci,
		English ,
		Fine_Arts,
		Foreign,
		Generaly,
		HealthPE,
		Math,
		OtherR,
		Professional,
		Science,
		Soc_Studies,
		SpEd,
		VocEd
		FROM eligcertS2
		ORDER BY lbjid;
QUIT;


PROC CONTENTS VARNUM;
RUN;


/* 3a RESTRUCTURE THE CERTIFICATION FILE INTO WIDE FORMAT*/

DATA STAND2.Certifications_WIDE(keep= lbjid 
asep_id1-asep_id5 
org_name_asep1-org_name_asep5
org_route1-org_route5
route_type1-route_type5
cert_type1-cert_type5
certtype_num1-certtype_num5
cert_id1-cert_id5
cert_effective1-cert_effective5
cert_day1-cert_day5
cert_month1-cert_month5
cert_year1-cert_year5
CERT_ELIGIBLE1-CERT_ELIGIBLE5
cert_area_mod1-cert_area_mod5
cert_area1-cert_area5
cert_grade1-cert_grade5
cert_desc1-cert_desc5
CERTCOUNT
Bilingual
CompSci
English 
Fine_Arts
Foreign
Generaly
HealthPE
Math
OtherR
Professional
Science
Soc_Studies
SpEd
VocEd);
     SET eligcerts2;
     BY lbjid;

     LENGTH asep_id1-asep_id5 $ 30
		    org_name_asep1-org_name_asep5 $ 40
		    org_route1-org_route5 $ 40
			route_type1-route_type5 $ 40
			cert_type1-cert_type5 $ 70
			cert_area1-cert_area5 $ 70
			cert_area_mod1-cert_area_mod5 $ 70
			cert_grade1-cert_grade5 $ 30
			cert_desc1-cert_desc5 $ 30;
    
/* retain variables to be output */ 
/* and retain pointer variable i */
     RETAIN asep_id1-asep_id5
		    org_name_asep1-org_name_asep5
		    org_route1-org_route5
			route_type1-route_type5 
			cert_type1-cert_type5
			certtype_num1-certtype_num5
		    cert_id1-cert_id5
			cert_effective1-cert_effective5
			cert_day1-cert_day5
			cert_month1-cert_month5
			cert_year1-cert_year5
			CERT_ELIGIBLE1-CERT_ELIGIBLE5
			cert_area1-cert_area5
			cert_area_mod1-cert_area_mod5
			cert_grade1-cert_grade5
			cert_desc1-cert_desc5 
			CERTCOUNT
			Bilingual
			CompSci
			English 
			Fine_Arts
			Foreign
			Generaly
			HealthPE
			Math
			OtherR
			Professional
			Science
			Soc_Studies
			SpEd
			VocEd
			i; 

            ARRAY asep (1:5)asep_id1-asep_id5;
            ARRAY epp (1:5) org_name_asep1-org_name_asep5;
            ARRAY oroute (1:5)org_route1-org_route5;
            ARRAY rtype (1:5)route_type1-route_type5;
            ARRAY cid  (1:5)cert_id1-cert_id5;
            ARRAY date (1:5)cert_effective1-cert_effective5;
			ARRAY day (1:5) cert_day1-cert_day5;
			ARRAY month (1:5)cert_month1-cert_month5;
			ARRAY year (1:5) cert_year1-cert_year5;
			ARRAY elig (1:5)CERT_ELIGIBLE1-CERT_ELIGIBLE5;
			ARRAY type (1:5)cert_type1-cert_type5;
			ARRAY typnum (1:5)certtype_num1-certtype_num5;
			ARRAY aream(1:5)cert_area_mod1-cert_area_mod5;
			ARRAY area (1:5)cert_area1-cert_area5;
			ARRAY grade(1:5)cert_grade1-cert_grade5;
			ARRAY desc (1:5) cert_desc1-cert_desc5 ;
	
			
			
 /* reset retained variables at start of MID BY group */

     IF first.lbjid THEN DO;
                       DO j= 1 to 5;
            asep(j)= ' ';
            epp(j)=	 ' ';
		    oroute(j)=' ' ;
	        rtype(j)= ' ' ;
            cid (j)=  .;
            date (j)= .;
			day (j)=  .; 
			month (j)=.;
			year (j) =.;
			elig (j)= .;
			type (j)=' ';
			typnum(j)=.;
			aream (j)= 	' ';
			type(j)= 	' ';
			area(j)=	' '; 
			grade(j)=	' ';
			desc(j)=	' ';
		END;
		i=1;
	END;
                           
  /* Assign values to output variables from variables in current input observation: */
            asep(i) = asep_id;
            epp(i) = org_name_asep;
            oroute(i)=org_route;
            rtype(i)=route_type;
            cid (i)= cert_id;
            date (i)= cert_effective;
			day (i)= cert_day; 
			month (i)= cert_month;
			year (i) =cert_year;
			elig (i)=CERT_ELIGIBLE;
			type (i)= cert_type;
			typnum(i) =certtype_num;
			aream(i)= cert_area_mod;
			area(i)= cert_area; 
			grade(i)=cert_grade;
			desc(i)= cert_desc;

/* increment i to point to next set of child variables */
     i= i + 1;
/* output observation if this is last child of mother */
     IF last.lbjid THEN OUTPUT; 

RUN;


/*3b Save the certifications file to the permannet library*/
*Tally the types of certificates by certification area;

DATA STAND2.certifications_WIDE;
SET STAND2.certifications_WIDE;

	ARRAY area [5] cert_area1-cert_area5;
	
      DO i= 1 to 5;
                       
		IF area(i) =	  	'Bilingual Education' 	THEN Bilingual = 1;
		IF area(i) = 	'Computer Science' 		THEN CompSci = 1;
		IF area(i) = 	'English Language Arts' THEN English = 1;
		IF area(i) = 	'Fine Arts' 			THEN Fine_Arts = 1;
		IF area(i)=	'Foreign Language' 		THEN Foreign = 1;
		IF area(i)=	'General Elementary (Self-Contained)' THEN Generaly = 1;
		IF area(i)=	'Health and Physical Education' THEN HealthPE = 1;
		IF area(i)= 	'Mathematics'			THEN Math = 1;
		IF area(i)=	'Other'					THEN OtherR = 1;
		IF area(i)=	'Professional'			THEN Professional = 1;
		IF area(i)=	'Science'				THEN Science = 1;
		IF area(i)=	'Social Studies'		THEN Soc_Studies = 1;
		IF area(i)=	'Special Education'		THEN SpEd = 1;
		IF area(i) = 	'Vocational Education' 	THEN VocEd = 1;
	END;
	DROP i;  
RUN;


  
PROC FREQ;
TABLES cert_area1-cert_area5 Bilingual VocEd;
RUN;

PROC SORT DATA = STAND2.certifications_WIDE;
BY asep_id1 lbjid;
RUN;
	
	
	
/* 3c SAVE THE FILE IN EXCEL FORMAT*/

	PROC EXPORT DATA=STAND2.Predistribution_CLEAN
	OUTFILE= 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\Data Files\Certifications_CLEAN_WIDE n =20084.xlsx'
	DBMS = EXCEL REPLACE;
	RUN;


***********************************************************************************************
/* 4 MERGE CERTIFICATION FILE WITH PREDISTRIBUTION FILE*/
*TEACHERS OR LBJIDS MUST BE IN BOTH DATA SETS TO BE INCLUDED IN THE FINAL PREDISTRIBUTION FILE;
***********************************************************************************************;

PROC SORT DATA=STAND2.Predistribution_CLEAN_WIDE;
	BY lbjid;
RUN;

PROC SORT DATA=STAND2.certifications_WIDE;
	BY lbjid;
RUN;


/* 4a MERGE AND SAVE THE FILE TO THE STAND2 LIBRARY*/
*predistribution file has N=21,363
*certs_wide N=20,084;
 
	DATA STAND2.FINAL_PREDISTRIBUTION;
		MERGE STAND2.Predistribution_CLEAN_WIDE (IN=PRECLEAN)
			  STAND2.Certifications_WIDE (IN=ELGCERTS);
			BY lbjid;
		IF PRECLEAN=1 AND ELGCERTS=1;
	RUN;
	

/* 4b SAVE THE FILE IN EXCEL FORMAT*/

	PROC EXPORT DATA=STAND2.FINAL_PREDISTRIBUTION
	OUTFILE= 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\Data Files\FINAL PREDISTRIBUTION_CLEAN n =20084.xlsx'
	DBMS = EXCEL REPLACE;
	RUN;






*NOW OPEN '3_Clean Principal Survey File.sas' ;
	