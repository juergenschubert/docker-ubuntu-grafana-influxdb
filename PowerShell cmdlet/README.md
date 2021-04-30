This is a repository for getting data from a DataDomain into InfluxDB.
Therefore I created a cmdlet Grafana-DataDomain without anything as this is a prototype right now. Please make sure that you import the module before you use it.   

>PS> Import-Module ./Grafana-DataDomain.psm1  -Force  

After the import, it should show you the available commands to be used with  

  
>PS /Users/juergen> Get-Command -Module Grafana-DataDomain
>
>CommandType     Name                                               Version    Source
>-----------     ----                                               -------    ------
>Function        Add-DDAlert2InfluxDB                               0.0        Grafana-DataDomain
>Function        Add-DDSystemCapacity2InfluxDB                      0.0        Grafana-DataDomain
>Function        Add-InfluxDB                                       0.0        Grafana-DataDomain
>Function        Add-InfluxMeasurement                              0.0        Grafana-DataDomain
>Function        Connect-DD                                         0.0        Grafana-DataDomain

There are two ways to get the data into an influxDB and you have to watch out on each command for switches like  

-dumpmeasuremen  
-add2InfluxDB  

Both do different things. While -add2InfluxDB is dumping into an InfluxDB and is creating the DB if not available
-dumpmeasuremen  - only writing you the insert statement for the InfluxDB cli.  

Before we can start we need to connect to our DD like:
>$DD = '3.66.161.175'  
>$DDtoken = Connect-DD $DD  

With that token, we can start the first metric the current and active alerts.
There are several command option you do get by  
>get-Help Connect-DD  

>get-help Add-InfluxDB 
>get-help Add-InfluxDB -example

#dump the measurement stadout for alerts
>Add-DDAlert2InfluxDB -DDfqdn $DD -DDAuthTokenValue $DDtoken -dumpmeasurement -InfluxDBServer 'localhost' -InfluxDB 'DDALERT' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' 

#add a measurement to InfluxDB
>Add-DDAlert2InfluxDB  -DDfqdn $DD -DDAuthTokenValue $DDtoken -add2InfluxDB -InfluxDBServer 'localhost' -InfluxDB 'DDALERT' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252'

#add logical/physical Capacity and Dedupe numbers int InfluxDB
>Add-DDSystemCapacity2InfluxDB -DDfqdn $DD -DDAuthTokenValue $DDtoken -dumpmeasurement -InfluxDBServer 'localhost' -InfluxDB 'DDSYSTEMCAPACITY' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' -DDtier 'active'
>Add-DDSystemCapacity2InfluxDB -DDfqdn $DD -DDAuthTokenValue $DDtoken -add2InfluxDB  -InfluxDBServer 'localhost' -InfluxDB 'DDSYSTEMCAPACITY' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' -DDtier 'active'
