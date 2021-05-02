This is a repository for getting data from a DataDomain into InfluxDB.
To give some help to query the data from the DataDomain and instert into InfluxDB I PowerShell cmdlet Grafana-DataDomain. This is writen and tested with PowerShell Core 7.1.3 only. Check with $PSVersionTable.PSVersion and $PSVersionTable.PSEditio befor you import.

>PS> Import-Module ./Grafana-DataDomain.psm1  -Force  

After the import, it should show you the available commands you can use  
  
>PS /Users/juergen> Get-Command -Module Grafana-DataDomain
>
>CommandType     Name                                               Version    Source
>-----------     ----                                               -------    ------
>Function        Add-DDAlert2InfluxDB                               0.0        Grafana-DataDomain
>Function        Add-DDSystemCapacity2InfluxDB                      0.0        Grafana-DataDomain
>Function        Add-InfluxDB                                       0.0        Grafana-DataDomain
>Function        Add-InfluxMeasurement                              0.0        Grafana-DataDomain
>Function        Connect-DD                                         0.0        Grafana-DataDomain

More details on the syntax of each command can be archived by running.  
> Get-Help Connect-DD 
> Get-Help Connect-DD -Example

There are two ways to get the data into an influxDB and you have to watch out on each command for switches like  

-dumpmeasurement  
-add2InfluxDB  

Both do different things. While -add2InfluxDB is dumping into an InfluxDB and is creating the DB if not available
-dumpmeasurement  - only writing the insert statment to stdout which you can copy and paste into InfluxDB cli.  

Before we can start we need to connect to our DD like:
>$DD = '3.66.161.175'  
>$DDtoken = Connect-DD $DD  

With that token, we can start the first metric the current and active alerts.
There are several command option you do get by  
>get-help Add-InfluxDB 
>get-help Add-InfluxDB -example

#dump the measurement stdout for alerts.  
>Add-DDAlert2InfluxDB -DDfqdn $DD -DDAuthTokenValue $DDtoken -dumpmeasurement -InfluxDBServer 'localhost' -InfluxDB 'DDALERT' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' 

#add a measurement to InfluxDB.   
>Add-DDAlert2InfluxDB  -DDfqdn $DD -DDAuthTokenValue $DDtoken -add2InfluxDB -InfluxDBServer 'localhost' -InfluxDB 'DDALERT' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252'

#dump the measurement stdout.   
>Add-DDSystemCapacity2InfluxDB -DDfqdn $DD -DDAuthTokenValue $DDtoken -dumpmeasurement -InfluxDBServer 'localhost' -InfluxDB 'DDSYSTEMCAPACITY' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' -DDtier 'active'

#add logical/physical Capacity and Dedupe numbers int InfluxDB.   
>Add-DDSystemCapacity2InfluxDB -DDfqdn $DD -DDAuthTokenValue $DDtoken -add2InfluxDB  -InfluxDBServer 'localhost' -InfluxDB 'DDSYSTEMCAPACITY' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' -DDtier 'active'
