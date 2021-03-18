# Overview
The purpose of this file is to overview how to navigate the EPA's data API known as the Air Quality System (AQS).  This overview is specifically for downloading data from a single site (i.e. DAQ Hawthorne, or Rosepark).   

The homepage for the AQS can be found here: https://aqs.epa.gov/aqsweb/documents/data_api.html

The AQS API works by sending requests via any web browser (i.e. chrome, firefox).  Once the request is received the API will send a response or data to the html page from which the request was issues. So all you need to do is enter a line of code with the appropriately structured request into the address bar of a web browser and wait for the data.


# STEP 1: Set Up a User Name and Get a Key
Open a web browser and enter the following command into the address bar:
https://aqs.epa.gov/data/api/signup?email=myemail@example.com

Replace "myemail@example.com" with the email address you want associated with your key.  The API will return a message informing you that the request was received and a key will be sent to the email you entered.  

The key they send you will be used in all subsequent data requests.  If you lose it you can always request a new one.


# STEP 2: Formatting a Request
The request commands are structured as a series of user selected variables.

Variable     | Description
-------------|------------
email        | The email you registered in Step 1 
key          | The key sent to that email
para         | The measurement (parameter) you want to download
bdate        | The start date you want to download* 
edate        | The end data you want to download*    
state        | The state the measurement site you want to download from resides in
county       | The county the measurement site you want to download from resides in
site         | The site ID you want to download data from

*Note: you can only download one year of data at a time

In the address bar of a web browser, enter the desired variables into the appropriate spots of the request command. An example of a fully executable request is below: 

**Example:**
https://aqs.epa.gov/data/api/sampleData/bySite?email=ryan.bares@utah.edu&key=tauperam28&param=42101&bdate=20180101&edate=20181231&state=49&county=035&site=3006

If you were to use the above request you would get CO data (param=42101) for the enitre year of 2018 (bdate=20180101, edate=20181231) from DAQ Hawthorne (site=3006) located in Salt Lake County (county=035), Utah (state=49).  Note that the email (email=ryan.bares@utah.edu) and the key (key=tauperam28) are for my utah.edu account, which was registered as described in **STEP 1** and will need to be changed to your email and key.


# Common Parameters for Air Quality Data

Species                      | Parameter Code
-----------------------------|----------------------------------
Carbon Monoxide (CO)         | 42101
Nitrogen Oxide (NO)          | 42601
Nitrogen Dioxide (NO2)       | 42602
Oxides of Nitrogen (NOx)     | 42603
Sulfur Dioxide (SO2)         | 42401
Particulate Matter (PM2.5)   | 88101

A list of all available parameters can be found by requesting the API to return a list using the following request:
https://aqs.epa.gov/data/api/list/parametersByClass?email=ryan.bares@utah.edu&key=tauperam28&pc=ALL

Don't forget to update the email and key! 

# Common Sites Codes for SLV
Site                         | Site Code
-----------------------------|----------------------------------
Hawthorne                    | 3006
Rose Park                    | 3010
Inland Port                  | 3017
Magna                        | 1001
Lake Park                    | 3014

List of all sites in Salt Lake County:
https://aqs.epa.gov/data/api/list/sitesByCounty?email=ryan.bares@utah.edu&key=tauperam28&state=49&county=035

Don't forget to update the email and key! 


# STEP 3: Saving Files From Web Browser
Once you have executed the command the API will return data to the html browser formatted for a .json file.  Note that it can take a while to receive all the data so be patient with it. 

To save the data from the html page to your local drive go to: 
**File -> Save Page As...** 

Name the file and select .json as the format. 

Boom!  You have successfully formatted a request for data from the EPA's AQS API, received that data and saved it!  



