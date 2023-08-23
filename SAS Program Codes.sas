***********************************************************MALE DATASET***********************************************************;
LIBNAME output '/home/u58374193/Assignment/Output';

**********************************************************************************;
* Load in csv file into sasfile													  ;
**********************************************************************************;
DATA output.MaleDataset;
INFILE '/home/u58374193/Assignment/Men shoe prices.csv' DLM="," DSD firstobs=2;
LENGTH	id asins brand categories colors count	dateAdded dateUpdated descriptions dimension ean features flavors imageURLs isbn keys manufacturer manufacturerNumber merchants product_name
		product_amountMin_bedit product_amountMax_bedit product_availability product_color product_condition product_count product_currency product_dateAdded product_dateSeen product_flavor
        product_isSale product_merchant product_offer product_returnPolicy product_shipping product_size product_source product_sourceURLs product_warranty quantities reviews sizes skus 
        sourceURLs upc vin websiteIDs weight $200;
INPUT 	id $ asins $ brand $ categories $ colors $ count dateAdded $ dateUpdated $ descriptions $ dimension $ ean $ features $  flavors $ imageURLs $  isbn $ keys $ manufacturer $ manufacturerNumber $
		merchants $ product_name $ product_amountMin_bedit $ product_amountMax_bedit $ product_availability $ product_color $ product_condition $	product_count $ product_currency $ product_dateAdded $
		product_dateSeen $ product_flavor $ product_isSale $ product_merchant $ product_offer $ product_returnPolicy $ product_shipping $ product_size $ product_source $ product_sourceURLs $ 
        product_warranty $ quantities $ reviews $ sizes $ skus $ sourceURLs $ upc $ vin $ websiteIDs $ weight $;
RUN;		


**********************************************************************************;
* Separate and Move the incorrect records to another output for cleaning		  ;
**********************************************************************************;
DATA CorrectMDBInput IncorrectMDBInput;
SET output.MaleDataset;
IF anyalpha(product_amountMin_bedit) OR anyalpha(product_amountMax_bedit) OR anyalpha(product_count) THEN output IncorrectMDBInput;
ELSE Output CorrectMDBInput;
RUN;


**********************************************************************************;
* Correct Incorrectly Inputted Records 											  ;
**********************************************************************************;
DATA IncorrectMDBInputCleaned;
SET IncorrectMDBInput;
	/*Array with the columns that contains value from product_name*/
	ARRAY columns {*} product_name product_amountMin_bedit product_amountMax_bedit product_availability product_color product_condition;
	/*Do loop to push them back into product_name*/
	DO n=1 to 8;
	    found=0;
	    DO i=2 to 6 until (found=1);
	    	product_name = translate(cats(product_name,'_',columns{i})," ","_");
	    	search = find(scan(product_name,-1),'"');
	    	columns{i}='';
	    	IF search ne 0 THEN found=1;
	   	END;
	    leave;
	END;

	/*Push back and adjust the rest of the column values that were pushed backed*/
  	ARRAY shiftcolumns {*} product_amountMin_bedit product_amountMax_bedit product_availability product_color product_condition product_count product_currency product_dateAdded product_dateSeen product_flavor product_isSale product_merchant product_offer product_returnPolicy product_shipping product_size product_source product_sourceURLs	product_warranty quantities reviews sizes skus sourceURLs upc vin websiteIDs weight;
    DO n=1 to (28-i);
    	shiftcolumns{n} = shiftcolumns{i};
    	i=i+1;
    END;
  	number = "0123456789";
  	IF findc(websiteIDs,number) eq 1 THEN DO;
    	upc = websiteIDs;
    	websiteIDs = '';
  	END;
  	IF findc(weight,number) eq 1 THEN DO;
    	upc = weight;
    	weight = '';
  	END;
  	IF findc(skus,"h") eq 1 THEN DO;
    	sourceURLs = skus;
    	skus = '';
  	END;
  	IF findc(vin,"h") eq 1 THEN DO;
	    sourceURLs = vin;
	    vin = '';
  	END;
  	IF findc(websiteIDs,"h") eq 1 THEN DO;
	    sourceURLs = websiteIDs;
	    websiteIDs = '';
  	END;
  	IF findc(weight,"h") eq 1 THEN DO;
	    sourceURLs = weight;
	    weight = '';
  	END;
DROP n found i search number;
RUN;


**********************************************************************************;
* Merge both IncorrectInputCleaned with CorrectInput							  ;
**********************************************************************************;
DATA CleanedMaleDataset00;
SET IncorrectMDBInputCleaned CorrectMDBInput;
RUN;


**********************************************************************************;
* Further cleaning on variables 												  ;
**********************************************************************************;
DATA CleanedMaleDataset01;
SET CleanedMaleDataset00;
	/*Change Casing*/
	brand = propcase(brand);
  
	/*Filter Product Name*/
	*Remove trailing " at the start and end of Product_Name;
	IF findc(product_name,'"') eq 1 
		THEN product_name = substr(product_name,2);
  	Pos = findc(product_name,'"','K',-length(product_name));
  	IF Pos
  		THEN product_name = substr(product_name, 1,Pos);
  	*Remove unnecessary string from Product_Name;
  	product_name = transtrn(product_name,"(men)",trimn(''));
  	product_name = transtrn(product_name,"[new]",trimn(''));
  	product_name = transtrn(product_name,"[bargain]",trimn(''));
  	product_name = transtrn(product_name,"[pw]",trimn(''));
  	product_name = transtrn(product_name,"�",trimn(''));
	
	/*Character Datatype Convert to Numerical Datatype*/
  	Product_amountMin = input(Product_amountMin_bedit,?? 8.2);
  	Product_amountMax = input(Product_amountMax_bedit,?? 8.2);
  	
	/*Date Formatting*/
  	product_dateAdded_date = input(substr(product_dateAdded,1,10), ?? yymmdd10.);
  	product_dateAdded_time = input(substr(product_dateAdded,12,8), ?? time8.);
  	product_dateSeen_date = input(substr(product_dateSeen,1,10), ?? yymmdd10.);
  	product_dateSeen_time = input(substr(product_dateSeen,12,8), ?? time8.);
  	product_dateAdded_datetime = dhms(product_dateAdded_date,0,0,product_dateAdded_time);
  	product_dateSeen_datetime = dhms(product_dateSeen_date,0,0,product_dateSeen_time);
  
	/*Adding variable - Gender*/
	Gender = 'Male';
	
/*Keep only the necessary variables needed for analysis*/
KEEP 	id asins brand categories product_name product_condition product_currency Product_amountMin product_amountMax product_dateAdded_datetime product_dateSeen_datetime Gender;
FORMAT 	Product_amountMin product_amountMax 8.2 product_dateAdded_datetime product_dateSeen_datetime datetime20.;
RUN;


**********************************************************************************;
* Drop duplicated records and keep the most updated ones						  ;
**********************************************************************************;
/*Remove records that are exactly the same*/
PROC SORT data=CleanedMaleDataset01 nodup;
BY _ALL_;
RUN;

/*Keep only the most recent record for each ID*/
PROC SQL;
CREATE TABLE CleanedMaleDataset02 AS
	SELECT *
	FROM CleanedMaleDataset01
	GROUP BY id
	HAVING product_dateAdded_datetime = max(product_dateAdded_datetime)
	AND product_dateSeen_datetime = max(product_dateSeen_datetime);
QUIT;


**********************************************************************************;
* Remove records that are not shoe related										  ;
**********************************************************************************;
DATA CleanedMaleDataset03; 
SET CleanedMaleDataset02;
/*Remove records that are not shoe related*/
category = compress(translate(categories,'',"',:;"));
	/*Keep Category that contains male shoe data*/
	Array toKeepCategories {3} $20 _TEMPORARY_ ('MensShoes','MenShoes','MensWork&SafetyShoes');
	DO i=1 to dim(toKeepCategories);
		IF prxmatch(cats("/",toKeepCategories{i},"/"),category) THEN isShoe = 1;
	END;
	
	/*Drop Category that were inputted but are not shoe*/
	Array toRemoveCategories {7} $20 _TEMPORARY_ ('MensSunglasses','Sunglasses&EyewearAccessories','AllWomensShoes','WomensShoes','AthleticSocks','MensSocks&Underwear','Bags&Accessories');	
	DO i=1 to dim(toRemoveCategories);
		IF prxmatch(cats("/",toRemoveCategories{i},"/"),category) THEN isShoe = 0; 
	END;
	
	/*Keep Product_Name that contains shoe keywords*/
	ARRAY tokeepKeywords {11} $10 _TEMPORARY_ ('slipper','shoe','sneaker','loafer','sandal','flip flop','boot','cleat','slip-on','footwear','trainers');
	DO i=1 to dim(tokeepKeywords);
		IF prxmatch(cats("/",tokeepKeywords{i},"/"),lowcase(product_name)) THEN isShoe = 1;
	END;	
	
	/*Drop Product_Name that were inputted but are not shoe*/
	ARRAY toRemoveKeywords {5} $10 _TEMPORARY_ ('headlight','headlamp','card','massaging','picture');
	DO i=1 to dim(toRemoveKeywords);
		IF prxmatch(cats("/",toRemoveKeywords{i},"/"),lowcase(product_name)) THEN isShoe = 0;
	END;	
	
IF isShoe = 1;
DROP i isShoe category;
RUN;


**********************************************************************************;
* Standarize Inconsistency found in Product_Condition							  ;
**********************************************************************************;
DATA CleanedMaleDataset04;
SET CleanedMaleDataset03;
	IF product_condition = 'new' OR product_condition = 'Brand New' THEN product_condition = 'New';
	ELSE IF product_condition = '' THEN product_condition = 'New';
RUN;


**********************************************************************************;
* Standarize Inconsistency found in Brand and Resolve Missing Values			  ;
**********************************************************************************;
DATA CleanedMaleDataset05;
SET CleanedMaleDataset04;
	/*Adjust inconsistency*/
	temp = lowcase(compress(translate(brand,'',"'.`-")));
	ARRAY bname1 {54} $20 _TEMPORARY_ ("adidas","and1","academie","avia","nike","converse","clarks","cudas","dc","diamondback","diesel","ellie","ferrini","fila","fitflop","generic","georgia","hoka","lacrosse","majestic","minnetonka","muck","neo","norcross","osiris","puma","pele","pleaser","rainbow","ranger","reebok","reef","ridge","rockport","servus","salomon","sendra","skechers","slipperooz","sorel","sperry","swear","toms","timberland","tingley","totes","ugg","vans","vionic","vasque","vince","wolverine","justin","zoot");
	DO i=1 to dim(bname1);
		IF prxmatch(cats("/",bname1{i},"/"),temp) THEN brand = bname1{i};
	END;

	ARRAY bname2 {38} $20 _TEMPORARY_ ("underarmor","airjordan","jordan","alexandermcqueen","perryellisportfolio","woodnstream","uspoloassn","uspolo","twistedxboots","baffininc","hugoboss","catfootwear","danpostboots","dije","drmartens","forevercollectible","goldenretriever","goldtoe","jsawake","kennethcole","kimberlyclark","levi","marcnewyork","newbalance","onitsukatiger","originalswat","ralphlauren","pfflyers","principleplastics","redwing","rivercity","robertwayne","gordonrush","softscience","teambeans","tonylama","alexanders","3n2");
	ARRAY newname {38} $20 _TEMPORARY_ ("Under Armour","Air Jordan","Air Jordan","Puma","Perry Ellis","Wood N Stream","U.S. Polo Assn.","U.S. Polo Assn.","Twisted X","Baffin","Hugo Boss","Caterpillar","Dan Post","Dije California","Dr. Martens","Forever Collectibles","Golden Retriever","Gold Toe","J's Awake","Kenneth Cole","Kimberly Clark","Levi's","Marc New York","New Balance","Onitsuka Tiger","Original S.W.A.T.","Ralph Lauren","Pf Flyers","Principle Plastics","Red Wing","River City","Robert Wayne","Gordon Rush","Soft Science","Team Beans","Tony Lama","alexander","3n2 Sports");
	DO i=1 to dim(bname2);
		IF prxmatch(cats("/",bname2{i},"/"),temp) THEN brand = newname{i};
	END;
	
	/*Resolve Missing Values in Brand*/
	*Based on their Product_Name;
	ARRAY bname3 {21} $20 _TEMPORARY_ ('Yu&yu','Crocs','Sofiamore','Icebug','New Balance','Salomon','Diamondback','Adidas','Clarks','Daxx','Marvel','Elten','Saucony','Sanuk','Ariat','Quiksilver',"Levi's",'Dunlop','Sebago','Pleaser','Liberty');
	DO i=1 to dim(bname3);
		IF prxmatch(cats("/",bname3{i},"/"),product_name) THEN brand = bname3{i};
	END;
	*Assign them to Unbranded since brand is unable to be identified;
	IF brand eq '' THEN brand='Unbranded';

brand = propcase(brand);
DROP i temp;
RUN;


**********************************************************************************;
* Computation to derive Product_Price									  		  ;
**********************************************************************************;
DATA output.MaleDatasetCleaned;
SET CleanedMaleDataset05;
	/*Find if there is a difference between product_amountMin and product_amountMax*/
	IF product_amountMin eq product_amountMax THEN amount = product_amountMax;
	ELSE amount = mean(product_amountMin, product_amountMax);

  	/*Changing currency to USD*/
  	IF product_currency = 'AUD' THEN DO;
  		amount = amount*1.35;
  		product_currency = 'USD';
  	END;
  	ELSE IF product_currency = 'CAD' THEN DO;
  		amount = amount*1.24;
  	  	product_currency = 'USD';
  	END;
  	ELSE IF product_currency = 'EUR' THEN DO;
  		amount = amount*0.86;
  		product_currency = 'USD';
  	END;
  	ELSE IF product_currency = 'GBP' THEN DO;
  		amount = amount*0.74;
  	  	product_currency = 'USD';
  	END;
  
amount = round(amount,0.01);
DROP product_amountMin product_amountMax product_currency;
RUN;



**********************************************************FEMALE DATASET**********************************************************;

**********************************************************************************;
* Load in csv file into sasfile													  ;
**********************************************************************************;
DATA output.FemaleDataset;
INFILE '/home/u58374193/Assignment/Women shoe prices.csv' DLM="," DSD firstobs=2;
LENGTH	id asins brand categories colors count	dateAdded dateUpdated descriptions dimension ean features flavors imageURLs isbn keys manufacturer manufacturerNumber merchants product_name
		product_amountMin_bedit product_amountMax_bedit product_availability product_color product_condition product_count product_currency product_dateAdded product_dateSeen product_flavor
        product_isSale product_merchant product_offer product_returnPolicy product_shipping product_size product_source product_sourceURLs product_warranty quantities reviews sizes skus 
        sourceURLs upc websiteIDs weight $200;
INPUT 	id $ asins $ brand $ categories $ colors $ count dateAdded $ dateUpdated $ descriptions $ dimension $ ean $ features $  flavors $ imageURLs $  isbn $ keys $ manufacturer $ manufacturerNumber $
		merchants $ product_name $ product_amountMin_bedit $ product_amountMax_bedit $ product_availability $ product_color $ product_condition $ product_count $ product_currency $ product_dateAdded $
		product_dateSeen $ product_flavor $ product_isSale $ product_merchant $ product_offer $ product_returnPolicy $ product_shipping $ product_size $ product_source $ product_sourceURLs $ 
        product_warranty $ quantities $ reviews $ sizes $ skus $ sourceURLs $ upc $ websiteIDs $ weight $;
RUN;	


**********************************************************************************;
* Separate and Move the incorrect records to another output for cleaning		  ;
**********************************************************************************;
DATA IncorrectFDBInput1 IncorrectFDBInput2 CorrectFDBInput;
SET output.FemaleDataset;
IF anyalpha(product_amountMin_bedit) OR anyalpha(Product_amountMax_bedit) OR anyalpha(product_count) THEN DO;
	IF Scan(product_name,-2,'"') ne '' THEN output IncorrectFDBInput2; /*Export product name found product name to other column*/
	ELSE output IncorrectFDBInput1; /*Merge product name found in other column to product_name*/
END;
ELSE Output CorrectFDBInput;
RUN;


**********************************************************************************;
* Correct Incorrectly Inputted Records 											  ;
**********************************************************************************;
/*IncorrectInput1*/
DATA IncorrectFDBInput1Cleaned;
SET IncorrectFDBInput1;
	/*Array with the columns that contains value from product_name*/
	ARRAY columns {*} product_name product_amountMin_bedit product_amountMax_bedit product_availability product_color product_condition;
	/*Do loop to push them back into product_name*/
	DO n=1 to 8;
		found=0;
		DO i=2 to 6 until (found=1);
			product_name = translate(cats(product_name,'_',columns{i})," ","_");
			search = find(scan(product_name,-1),'"');
			columns{i}='';
			IF search ne 0 THEN found=1;
		END;
		leave;
	END;
	
	/*Push back and adjust the rest of the column values that were pushed backed*/
	ARRAY shiftcolumns {*} product_amountMin_bedit product_amountMax_bedit product_availability product_color product_condition product_count product_currency product_dateAdded product_dateSeen product_flavor product_isSale product_merchant product_offer product_returnPolicy product_shipping product_size product_source product_sourceURLs	product_warranty quantities reviews sizes skus sourceURLs upc websiteIDs weight;
	DO n=1 to (27-i);
		shiftcolumns{n} = shiftcolumns{i};
		i=i+1;
	END;
	number = "0123456789";
	IF findc(websiteIDs,number) eq 1 THEN DO;
		ean = websiteIDs;
		websiteIDs = '';
	END;
	IF findc(sourceURLs,number) eq 1 THEN DO;
		ean = sourceURLs;
		sourceURLs = '';
	END;
	IF findc(weight,"h") eq 1 THEN DO;
		product_sourceURLs = weight;
		weight = '';
	END;
DROP n found i search number;
RUN;

/*IncorrectInput2 : Split Dataset for cleaning into Merge1 and Merge2*/
DATA FDBMerge1;
	SET IncorrectFDBInput2;
	extract = cats(Scan(product_name,-2,'"'),',');
	numcol = countc(extract,',');
	ARRAY colpos {8}  _temporary_;
	ARRAY colval {7} $ _temporary_;
	pos=0;
	DO i=1 to numcol;
		pos = find(extract,',',pos+1);
		colpos{i} = pos;
	END;
	DO i=1 to numcol-1;
		IF colpos{i}+1 eq colpos{i+1} THEN DO;
			colval{i} = "";
			END;
		ELSE 
			colval{i} = substr(extract,colpos{i}+1,colpos{i+1}-(colpos{i}+1));
	END;
	/*Substitude in the values*/
	ARRAY subst {*} product_amountMin_bedit product_amountMax_bedit product_availability product_color product_condition product_count product_currency product_dateAdded product_dateSeen product_flavor product_isSale product_merchant product_offer product_returnPolicy product_shipping product_size product_source product_sourceURLs product_warranty quantities reviews sizes skus sourceURLs upc websiteIDs weight;
	DO i=1 to 7;
		subst{i} = colval{i};
	END;
	DO i=8 to 27;
		subst{i} = '';
	END;
	uid = _n_;
	DROP i numcol extract pos product_currency product_dateAdded product_dateSeen product_flavor product_isSale product_merchant product_offer product_returnPolicy product_shipping product_size product_source product_sourceURLs	product_warranty quantities reviews sizes skus sourceURLs upc websiteIDs weight;
RUN;

DATA FDBMerge2;
	SET IncorrectFDBInput2;
	sub = Scan(product_name,-2,'"');
	numcol = countc(sub,',')+1;
	i=1;
	/*Shift Records accordingly*/
	ARRAY shiftcolumns {*} product_amountMin_bedit product_amountMax_bedit product_availability product_color product_condition product_count product_currency product_dateAdded product_dateSeen product_flavor product_isSale product_merchant product_offer product_returnPolicy product_shipping product_size product_source product_sourceURLs	product_warranty quantities reviews sizes skus sourceURLs upc websiteIDs weight;
	ARRAY testing {27} $ 200 _temporary_;
	DO n=numcol to 27;
		testing{n} = shiftcolumns{i};
		i = i+1;
	END;
	/*Append The Column Record*/
	DO n=1 to numcol;
		shiftcolumns{n} = '';
	END;
	DO n=numcol to 27;
		shiftcolumns{n} = testing{n};
	END;
	product_currency = 'USD';
	uid = _n_;
	DROP sub numcol i n;
	KEEP product_currency product_dateAdded product_dateSeen product_flavor product_isSale product_merchant product_offer product_returnPolicy product_shipping product_size product_source product_sourceURLs	product_warranty quantities reviews sizes skus sourceURLs upc websiteIDs weight uid; 
RUN;

/*Merge Marge1 and Merge2 together into IncorrectInput2Cleaned*/
DATA IncorrectFDBInput2Cleaned;
	MERGE FDBMerge1 FDBMerge2;
	BY uid;
	product_name = substr(product_name,1,findc(product_name,'"')-1);
	DROP uid;
RUN;

/*Merge IncorrectInput1 and IncorrectInput2 into IncorrectInputCleaned*/
DATA IncorrectFDBInputCleaned;
	SET IncorrectFDBInput1Cleaned IncorrectFDBInput2Cleaned;
RUN;


**********************************************************************************;
* Merge both IncorrectInputCleaned with CorrectInput							  ;
**********************************************************************************;
DATA CleanedFemaleDataset00;
SET IncorrectFDBInputCleaned CorrectFDBInput;
RUN;


**********************************************************************************;
* Further cleaning on variables 												  ;
**********************************************************************************;
DATA CleanedFemaleDataset01;
SET CleanedFemaleDataset00;
	/*Changing Casing*/
	brand = propcase(brand);
	
	/*Filter Product Name*/
	*Remove trailing " at the start and end of Product_Name;
	IF findc(product_name,'"') eq 1 
		THEN product_name = substr(product_name,2);
	Pos = findc(product_name,'"','K',-length(product_name));
	IF Pos
    	THEN product_name = substr(product_name, 1,Pos);
  	*Remove unnecessary string from Product_Name;
  	product_name = transtrn(product_name,"(women)",trimn(''));
  	product_name = transtrn(product_name,"* New *",trimn(''));
  	product_name = transtrn(product_name,"* new *",trimn(''));
  	product_name = transtrn(product_name,"**new**",trimn(''));
  	product_name = transtrn(product_name,"*new*",trimn(''));
  	product_name = transtrn(product_name,"**just In**",trimn(''));
  	product_name = transtrn(product_name,"�",trimn('')); 
	
	/*Character Datatype Convert to Numerical Datatype*/
  	Product_amountMin = input(Product_amountMin_bedit,?? 8.2);
  	Product_amountMax = input(Product_amountMax_bedit,?? 8.2);
	
	/*Date Formatting*/
	product_dateAdded_date = input(substr(product_dateAdded,1,10), ?? yymmdd10.);
	product_dateAdded_time = input(substr(product_dateAdded,12,8), ?? time8.);
	product_dateSeen_date = input(substr(product_dateSeen,1,10), ?? yymmdd10.);
	product_dateSeen_time = input(substr(product_dateSeen,12,8), ?? time8.);
	product_dateAdded_datetime = dhms(product_dateAdded_date,0,0,product_dateAdded_time);
  	product_dateSeen_datetime = dhms(product_dateSeen_date,0,0,product_dateSeen_time);

	/*Adding variable - Gender*/
	Gender = 'Female';

/*Keep only the necessary variables needed for analysis*/
KEEP 	id asins brand categories product_name product_condition product_currency Product_amountMin product_amountMax product_dateAdded_datetime product_dateSeen_datetime Gender;
FORMAT 	Product_amountMin product_amountMax 8.2 product_dateAdded_datetime product_dateSeen_datetime datetime20.;
RUN;


**********************************************************************************;
* Drop duplicated records and keep the most updated ones						  ;
**********************************************************************************;
/*Remove records that are exactly the same*/
PROC SORT data=CleanedFemaleDataset01 nodup;
BY _ALL_;
RUN;

/*Keep only the most recent record for each ID*/
PROC SQL;
CREATE TABLE CleanedFemaleDataset02 AS
	SELECT *
	FROM CleanedFemaleDataset01
	GROUP BY id
	HAVING product_dateAdded_datetime = max(product_dateAdded_datetime)
	AND product_dateSeen_datetime = max(product_dateSeen_datetime);
QUIT;


**********************************************************************************;
* Remove records that are not shoe related										  ;
**********************************************************************************;
DATA CleanedFemaleDataset03;
SET CleanedFemaleDataset02;
/*Remove records that are not shoe related*/
category = compress(translate(categories,'',"',:;&"));
	/*Keep Category that contains female shoe data*/	
	Array toKeepCategories {3} $20 _TEMPORARY_ ('WomensShoes','WomenShoes','WomensDressShoes');
	DO i=1 to dim(toKeepCategories);
		IF prxmatch(cats("/",lowcase(toKeepCategories{i}),"/"),lowcase(category)) THEN isShoe = 1;
	END;
	
	/*Drop Category that were inputted but are not shoe*/
	Array toRemoveCategories {1} $30 _TEMPORARY_ ('SunglassesEyewearAccessories');
	DO i=1 to dim(toRemoveCategories);
		IF prxmatch(cats("/",lowcase(toRemoveCategories{i}),"/"),lowcase(category)) THEN isShoe = 0;
	END;
	
	/*Keep Product_Name that contains shoe keywords*/
	ARRAY toKeepKeywords {16} $10 _TEMPORARY_ ('oxford','heel','clog','pump','flat','slipper','shoe','sneaker','loafer','sandal','flip flop','boot','cleat','slip-on','footwear','trainers');
	DO i=1 to dim(toKeepKeywords);
		IF prxmatch(cats("/",toKeepKeywords{i},"/"),lowcase(product_name)) THEN isShoe = 1;
	END;
	
	/*Drop Product_Name that were inputted but are not shoe*/
	Array toRemoveKeywords {6} $20 _TEMPORARY_ ('pant','jean','shirt','sunglass','handbag','shorts');
	DO i=1 to dim(toRemoveKeywords);
		IF prxmatch(cats("/",toRemoveKeywords{i},"/"),lowcase(product_name)) THEN isShoe = 0;
	END;	
	
	/*Remove any male shoes*/
	IF findw(lowcase(product_name),"men's") OR findw(lowcase(product_name),"mens") OR findw(lowcase(product_name),"men") THEN isShoe = 0;

IF isShoe = 1;
DROP i isShoe category;
RUN;


**********************************************************************************;
* Standarize Inconsistency found in Product_Condition							  ;
**********************************************************************************;
DATA CleanedFemaleDataset04;
SET CleanedFemaleDataset03;
	IF product_condition = 'new' OR product_condition = 'Brand New' THEN product_condition = 'New';
	ELSE IF product_condition = '' THEN product_condition = 'New';
RUN;


**********************************************************************************;
* Standarize Inconsistency found in Brand and Resolve Missing Values			  ;
**********************************************************************************;
DATA CleanedFemaleDataset05;
SET CleanedFemaleDataset04;
	/*Adjust inconsistency*/
	temp = lowcase(compress(translate(brand,'',"'.`-")));
	ARRAY bname1 {49} $20 _TEMPORARY_ ('alegria','alpine','annie','aerosoles','babe','bamboo','baretraps','carlos','clarks','corral','dbdk','diba','drew','emu','fergie','fitflop','funtasma','guess','impo','intaglia','jambu','lamo','madeline','mia','mephisto','muck','naot','newton','nina','nocona','nufoot','patrizia','pleaser','rieker','rockport','rampage','skechers','sorel','sperry','theatricals','timberland','toms','totes','vaneli','vans','vionic','wanted','zigi','zoot');
	DO i=1 to dim(bname1);
		IF prxmatch(cats("/",bname1{i},"/"),temp) THEN brand = bname1{i};
	END;

	ARRAY bname2 {55} $20 _TEMPORARY_ ('361','anneklein','boc','berniemev','breckelle','breckelles','calvinkleinck','charlesdavid','chase+chloe','cityclassified','newbalance','corkys','deblossom','cityclassified','drmartens','dolcevita','easyspirit','ellie','giamia','halston','isaacmizrahi','italianshoemakers','jrenee','katespade','kennethcole','lartiste','ralphlauren','lifestride','luckybrand','luoluo','marcjacobs','marcfisher','walkingcradles','micahelkors','michaelkors','michaelantonio','mtngorignals','mukluks','nicole','ninewest','rachelroy','rocketdog','romacostume','stevemadden','style&co','whitemountain','summitfashions','benjaminwalk','touchups','trotter','uggaustralia','unlisted','veryfine','victoriak','vince');
	ARRAY newname {55} $20 _TEMPORARY_ ('361 Degrees','Anne Klein','B.O.C.','Bernie Mev',"Breckelle's","Breckelle's",'Calvin Klein','Charles David','Chase & Chloe','City Classified','New Balance',"Corky's",'De Blossom','City Classified','Dr. Martens','Dolce Vita','Easy Spirit','Ellie Shoes','Giani Bernini','Halston Heritage','Isaac Mizrahi','Italian Shoe Makers','J. Renee','Kate Spade','Kenneth Cole',"L'artiste",'Ralph Lauren','Life Stride','Lucky Brand','Luo Luo','Marc Jacobs','Marc Fisher','Walking Cradles','Michael Kors','Michael Kors','Michael Antonio','Mtng Originals','Muk Luks','Nicole Miller','Nine West','Rachel Roy','Rocket Dog','Roma Costumes','Steve Madden','Style & Co.','White Mountain','Summit Fashions','Benjamin Walk','Benjamin Walk','Trotters','Ugg','Kenneth Cole','Very Fine','Victoria K.','Vince Camuto');
	DO i=1 to dim(bname2);
		IF prxmatch(cats("/",bname2{i},"/"),temp) THEN brand = newname{i};
	END;
	
	/*Resolve Missing Values in Brand*/
	*Based on their Product_Name;
	ARRAY bname3 {10} $20 _TEMPORARY_ ('Yu&yu','Sneed','Brinley Co.','Adidas','Cxyy','Asics','Capezio','Nine West','Valanty','Sansha');
	DO i=1 to dim(bname3);
		IF prxmatch(cats("/",bname3{i},"/"),product_name) THEN brand = bname3{i};
	END;
	*Assign them to Unbranded since brand is unable to be identified;
	IF brand eq '' THEN brand='Unbranded';

brand = propcase(brand);
DROP i temp;
RUN;


**********************************************************************************;
* Computation to derive Product_Price									  		  ;
**********************************************************************************;
DATA output.FemaleDatasetCleaned;
SET CleanedFemaleDataset05;
	/*Find if there is a difference between product_amountMin and product_amountMax*/
	IF product_amountMin eq product_amountMax THEN amount = product_amountMax;
	ELSE amount = mean(product_amountMin, product_amountMax);

  	/*Changing currency to USD*/
  	IF product_currency = 'AUD' THEN DO;
  		amount = amount*1.35;
  		product_currency = 'USD';
  	END;
  	ELSE IF product_currency = 'CAD' THEN DO;
  		amount = amount*1.24;
  	  	product_currency = 'USD';
  	END;
  	ELSE IF product_currency = 'EUR' THEN DO;
  		amount = amount*0.86;
  		product_currency = 'USD';
  	END;
  	ELSE IF product_currency = 'GBP' THEN DO;
  		amount = amount*0.74;
  	  	product_currency = 'USD';
  	END;

amount = round(amount,0.01);
DROP product_amountMin product_amountMax product_currency;
RUN;



***********************************************************MERGE DATASET***********************************************************;

**********************************************************************************;
* Merge Both Male and Female Datasets											  ;
**********************************************************************************;
DATA output.ShoeDataset 
	(rename=(product_condition=shoe_condition
			 amount=shoe_price
			 product_name=shoe_name));
SET output.FemaleDatasetCleaned (obs=8000) output.MaleDatasetCleaned (obs=8000);
DROP categories product_dateAdded_datetime product_dateSeen_datetime;
RUN;