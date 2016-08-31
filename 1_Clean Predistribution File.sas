******2014-15 STANDARD 2 ASEP ANALYSIS****;
**PART I. Clean the predistribution file**;
******************************************;
******************************************;

LIBNAME STAND2 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\SAS Files';

*********************************************************;
/*STEP 1: DETERMINE CORRECT SAMPLE OF EPPs for 2014-15*/
*********************************************************;


/*IMPORT THE EXCEL FILE*/

	PROC IMPORT OUT= Predistribution 
			DATAFILE= "I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\TEA Excel Files\Predistribution Survey Data with EPP List 2015.xlsx" 
	            DBMS=EXCEL REPLACE;
	     SHEET="PREDISTRIBUTION DATA 2014-15"; 
	     GETNAMES=YES;
	RUN;


*EXPLORE THE DATASET (n, variables, range of values);
 
	PROC CONTENTS DATA=Predistribution
		VARNUM;
	RUN;
	
	PROC SORT DATA=Predistribution;
	BY lbjid district_num campus_num asep_id;
	RUN;
	
	PROC PRINT DATA=Predistribution;
	RUN; 

	
/* 1a-DELETE STATE BOARD CERTIFICATIONS BY EXAM, n= 8138*/

	PROC PRINT NOOBS N;
	VAR lbjid asep_id org_name_asep;
		WHERE asep_id = '227619';
	RUN;
	
/* 1b DELETE OBSERVATIONS THAT DO NOT HAVE AN ASSOCIATED EPP, n=3486 */

	PROC PRINT NOOBS N;
	VAR lbjid asep_id org_name_asep;
		WHERE asep_id = '';
	RUN;
	
	DATA Predist;
		SET Predistribution;
		IF asep_id = '227619' OR asep_id = '' THEN DELETE;
	RUN;

/*CHANGE THE ID VARIABLE FORMATS (CONVERT CHARS TO NUMERIC)*/

	DATA Predist2;
		SET Predist;
	    asepidD = INPUT(asep_id, 6.);
	    asepid=PUT(asepidD, z6.);
	    campusD= INPUT(campus_num, 6.);
	    campusid=PUT(campusD, z6.);
	    districtD= INPUT(district_num, 9.);
	    districtid = PUT(districtD, z9.);
	    roleid = PUT(role_id, 3.);
	    yoe_tot = PUT(total_years_exper, 3.);
	    yoe_dist= PUT(years_exper_district, 3.);
	    ISD = SCAN(org_name_asep, -1, ' ');
	 RUN;
	    
	 PROC SORT DATA = Predist2;
		 BY asepid;
	 RUN;   
	    
/* CONFIRM VALID 2014-15 EPP LIST*/
	PROC FREQ DATA=Predist2;
	TABLES org_name_asep;
	RUN;
		
*COMPARE AGAINST THE OFFICIAL LIST OF 2014-15 EPPs (n=143);

	PROC IMPORT OUT=epp
			DATAFILE= "I:\Austin Analytics\ASEP Standard 2 Data 2014-15\TEA Excel Files\2014-15 EPP List Type and Sub Type n=143.xlsx"
	            DBMS=EXCEL REPLACE;
	     SHEET="Recovered_Sheet1"; 
	     GETNAMES=YES;
	RUN;	
	
	
	DATA STAND2.epps_all;
	SET epp;
		asepidD = INPUT(asep_id, 6.);
	    asepid=PUT(asepidD, z6.);
	RUN;
	
	PROC SORT DATA= STAND2.epps_all;
		BY asepid;
	RUN;


/* 1c *Using the official list as a key, merge the predist to eliminate superfluous ISDs and EPPs; */

	DATA OFFEPPS (KEEP=lbjid roleid yoe_tot yoe_dist asepid org_name_asep org_route route_type asep_status1415 Region Finished2015 districtid district_name campusid campus_name prin_id First);
		MERGE STAND2.epps_all (in=epp143)
			  WORK.Predist2 (in=pred);
		BY asepid;
		First = first.asepid;
		Last =  last.asepid;
		IF epp143=1 AND pred=1;
	RUN;

	
TITLE2 "2015-15 EPPs in Predistribution File";
	PROC PRINT DATA = WORK.OFFEPPS N;
	VAR asepid org_name_asep;
		WHERE First = 1;
	RUN;
TITLE2;

*134 of 143 EPPS are present in the predistribution file;	
	
*Determine the 9 EPPs that are not in the 2014-15 Predistribution file sample;

DATA Dregs;
 MERGE WORK.OFFEPPS(in=sample)
	   STAND2.epps_all(in=onefortythree);
	  BY asepid;
	  IF onefortythree=1 AND sample=0;
	 RUN;
	
TITLE3 "EPPS Without Survey Data";
	PROC PRINT DATA = Dregs N;
	 VAR asepid org_name_asep;
	RUN;
TITLE3;

proc freq data =STAND2.epps_all;
tables org_route route_type;
run;

/*1e-REMOVE REDUNDANT VARIABLES*/

DATA WORK.PRE (KEEP=lbjid roleid yoe_tot yoe_dist asepid org_name_asep org_route route_type asep_status1415 Region Finished2015 districtid district_name campusid campus_name prin_id
				RENAME=(asepid=asep_id roleid=role_id districtid=district_id campusid=campus_id));
	 SET WORK.OFFEPPS;
RUN;
	
	
	
**********************************************************;
/*STEP 2: IDENTIFY AND REMOVE DUPLICATE RECORDS (SURVEYS)*/
**********************************************************;

/*2a CHECK FOR TEACHER DUPLICATES*/	
	
	PROC FREQ DATA=PRE 
		ORDER=FREQ;
		TABLES lbjid / OUT=dupeteach ; 
	RUN;
	
	TITLE4 'TEACHER CANDIDATE DUPLICATES';
	PROC PRINT DATA= dupeteach N;
		WHERE count ge 2;
		RUN;
	TITLE4;

/*2b CHECK FOR TEACHER DUPLICATES*/	

	PROC FREQ DATA=WORK.PRE
		ORDER=FREQ;
		TABLES lbjid*district_id*campus_id /NOPRINT OUT=dupeteachcamp ; 
	RUN;

	TITLE5 'TEACHER CANDIDATE DUPLICATE DISTRICTS AND CAMPUSES';
	PROC PRINT DATA=dupeteachcamp N;
		WHERE count ge 2;
	RUN;
	TITLE5;
	
	
/*2c CHECK FOR TEACHER DUPLICATES*/
	PROC FREQ DATA=WORK.PRE
		ORDER=FREQ;
		TABLES lbjid*asep_id /NOPRINT OUT=dupeEPP ; 
	RUN;

	TITLE6 'TEACHER CANDIDATE WITH DUPLICATE EPPs';
	PROC PRINT DATA=dupeEPP N;
		WHERE count ge 2;
	RUN;
	TITLE6;


	PROC SORT DATA=WORK.PRE NODUPKEY OUT=norealdupes;
		BY lbjid asep_id district_id campus_id ;
	RUN;
	
	
	PROC PRINT DATA=WORK.PRE N;
	RUN;
	
	PROC SORT DATA= WORK.norealdupes;
		BY lbjid asep_id district_id campus_id;
	RUN;
	
	PROC PRINT DATA=WORK.norealdupes N;
		VAR lbjid asep_id district_id campus_id;
	RUN;
	
	/*NOW EXAMINE DUPLCITY AGAIN (QUALITY ASSURANCE)*/

	PROC FREQ DATA=WORK.NOREALDUPES
		ORDER=FREQ;
		TABLES lbjid*asep_id*district_id*campus_id /NOPRINT OUT=dupes; 
	RUN;

	
	PROC FREQ DATA=WORK.NOREALDUPES
		ORDER=FREQ;
		TABLES lbjid /NOPRINT OUT=dupeslbjids; 
	RUN;
	
	
	TITLE6 'FINAL TEACHER CANDIDATES';
	PROC PRINT DATA=WORK.dupeslbjids N;
		WHERE count ge 2;
		RUN;
	TITLE6;
	RUN;
	

	TITLE7 'TEACHER CANDIDATE WITH DUPLICATE EPPs';
	PROC PRINT DATA=WORK.dupes N;
		WHERE count ge 2;
		RUN;
	TITLE7;
	RUN;
	
	TITLE8 'LEGITMATE RECORDS';
	PROC PRINT DATA=WORK.norealdupes N;
		VAR lbjid asep_id district_id campus_id ;
		RUN;
	TITLE8;
	RUN;


**********************************************************;
/*STEP 3: FORMAT AND SAVE THE PRE DISTRIBUTION FILES)*/
**********************************************************;


/* 3a SAVE THE FILE TO THE STAND2 LIBRARY
INVOKE SQL FOR AN EASY WAY TO REORDER VARIABLES AS DESIRED*/

PROC SQL;
	CREATE TABLE STAND2.Predistribution_CLEAN AS
		SELECT lbjid, role_id, yoe_tot, yoe_dist, asep_id, org_name_asep, org_route, route_type, asep_status1415, Region, Finished2015, district_id, district_name, campus_id, campus_name, prin_id
		FROM WORK.norealdupes;
QUIT;


/* 3b Resstructure the file from LONG to WIDE
(2 IS THE MAXIMUM NUMBER OF RECORDS FOR A TEACHER)*/

DATA STAND2.Predistribution_CLEAN_WIDE
			(KEEP=lbjid yoe_tot1 
				yoe_tot2  Region1 Region2 
				Finished20151 Finished20152);
			
	 SET STAND2.Predistribution_CLEAN;
	 BY lbjid;
	 LENGTH 	yoe_tot1 $ 30
				yoe_tot2 $ 30;
				
/* retain variables to be output */ 
/* and retain pointer variable i */
     RETAIN lbjid yoe_tot1 yoe_tot2
				yoe_dist1 yoe_dist2
				Region1 Region2
				Finished20151 Finished20152	
			i; 
		
			ARRAY yoetot(1:2) yoe_tot1 yoe_tot2;
			ARRAY regions (1:2) Region1 Region2;
			ARRAY fin (1:2) Finished20151 Finished20152;

 *reset retained variables at start of lbjid BY group;

     IF first.lbjid THEN DO;
                       DO j= 1 to 2;
		
            yoetot(j) = ' ';
			regions (j)= .;
			fin (j)= .;
			   
		END;
		i=1;
	END;
            
                           
  * Assign values to output variables from variables in current input observation;
			 
			yoetot(i)=yoe_tot ;
			regions(i)= Region;
			fin (i)= Finished2015;	

* increment i to point to next set of child variables;
     i= i + 1;

* output observation if this is last child of mother;
     IF last.lbjid THEN OUTPUT; 
    
RUN;

/* 3c SAVE THE FILE IN EXCEL FORMAT*/

	PROC EXPORT DATA=STAND2.Predistribution_CLEAN_WIDE
	OUTFILE= 'I:\Austin Analytics\ASEP Standard 2 Data 2014-15\Data\Data Files\Predistribution_CLEAN_WIDE n =21363.xlsx'
	DBMS = EXCEL REPLACE;
	RUN;




*NOW OPEN '2_Clean Certification File.sas' 
	
	
	
		