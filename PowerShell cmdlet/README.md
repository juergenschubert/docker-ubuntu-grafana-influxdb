This is repository for getting data from a DataDomain into InfluxDB.
Therefor I created a cmdlet Grafana-DataDomain with out anything as this is a protype right now. Please make sure you that you import the module before you use it.   
Import-Module ./Grafana-DataDomain.psm1  -Force  
After the import it should show you the avaialbe commands to be used with  
Get-Command -Module Grafana-DataDomain    

There are two ways to get the data into an influxDB and you have to watchout on each command for switches like  
-dumpmeasuremen  
-add2InfluxDB  

Both do differtent things. While -add2InfluxDB is dumping into a InfluxDB and is creating the DB if not available
-dumpmeasuremen  is onyl writing you the insert statement for the InfluxDB cli.  

Before we can start we need to connect to our DD like:
$DD = '3.66.161.175'  
$DDtoken = Connect-DD $DD  

With that token we can start the first metric the current and active alerts  .
There are several command option you do get by  
get-Help Connect-DD
get-Help Get-DDAlert

#dump the measurement
Get-DDAlert  -DDfqdn $DD -DDAuthTokenValue $DDtoken -dumpmeasurement -InfluxDBServer 'localhost' -InfluxDB 'DDALERT' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' 

#add a measurement to InfluxDB
Get-DDAlert  -DDfqdn $DD -DDAuthTokenValue $DDtoken -add2InfluxDB -InfluxDBServer 'localhost' -InfluxDB 'DDALERT' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252'