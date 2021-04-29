# Visualize YOUR DataDomain capacity/performance data with Grafana

The Dashboard showing some Information about your DD 
![DDGrafana-dashboard](https://user-images.githubusercontent.com/17120076/116557229-8adf9480-a8fe-11eb-8a51-5d450fe4b8a3.gif)

Visualize the DD Alerts of your DataDomain.   
![DDGrafana-Alert](https://user-images.githubusercontent.com/17120076/116557252-90d57580-a8fe-11eb-969b-eb09293672db.gif)

Visualize the capacity of your DataDomain.  
![DDGrafana-capacity](https://user-images.githubusercontent.com/17120076/116557278-96cb5680-a8fe-11eb-82d4-fb0525fcc041.gif)

Visualize the performance/troughput of your DataDomain.  
![DDGrafana-performance](https://user-images.githubusercontent.com/17120076/116558299-91224080-a8ff-11eb-81f0-19f5430ec3ac.gif)

Visualize the streams of your DataDomain
![DDGrafana-streams](https://user-images.githubusercontent.com/17120076/116391883-01f22b80-a820-11eb-95f5-e02b007dd085.gif) 

# How can you archive these nice Grafana dashboards in your environment?   

I am using a Docker image with **Grafana** and **InfluxDB** which is:    
https://hub.docker.com/r/philhawthorne/docker-influxdb-grafana/     
You find how to start and how to use it on his page.
If you where using a **Windows PC**, install the Docker Desktop first.

ensure that you have the following both directories ready to be used for Grafana and InfluxDB config and database storage:  
>C:\Users\schubj2\Documents\grafana-influx\influxdb     
>C:\Users\schubj2\Documents\grafana-influx\grafana   

Windows terminal/CLI
>docker run -d --name docker-influxdb-grafana -p 3003:3003 -p 3004:8003 -p 8086:8086 -v C:\Users\schubj2\Documents\grafana-influx\influxdb:/var/lib/influxdb -v C:\Users\schubj2\Documents\grafana-influx\grafana:/var/lib/grafana philhawthorne/docker-influxdb-grafana:latest


**Why Grafana and InfluxDB**?   
Because this is an **best way** to visualize the content of a time series DB - InfluxDB which got their series data from **YOUR** DataDomain.  

The **high-level concept** is to deploy Grafana and InfluxDB either on Linux or with docker, import the DataDomain Grafana dashboards for the visualization you see above, and use the **PowerShell cmdlet** to get live data from your DataDomain into InfluxDB which is the data source for Grafana. This can also be automated so you get these updates regularly and your Grafan will also show history. **BUT** watch-out as data will grow! Ensure that you either have enough space or delete older series manually or use [InfluxDB retention policies](https://docs.influxdata.com/influxdb/v1.8/guides/downsample_and_retain/)


The folder in this GitHub repo will contain the following information.   
![Screen Shot 2021-04-29 at 09 49 03](https://user-images.githubusercontent.com/17120076/116518131-2ad1f980-a8d0-11eb-9a75-93480a258c36.png)

## Grafana and InfluxDB  
This will contain the docker file if you wanna create your own instead of consuming https://hub.docker.com/r/philhawthorne/docker-influxdb-grafana/.                   
## Grafana dashboard  
Here you do find the latest and greatest Grafana dashboard. 

## PowerShell cmdlet  
Here you do find the latest PowerShell cmdlet which will query the DD and publish the result to InfluxDB.             

**More will come - let me know what you need**
# Tips and tricks

## How to add DDALERT DB on your InfluxDB?
start a ssh and go to your InfluxDB.   
start the influxdb cli with:   
>influx  
>CREATE DATABASE DDALERT

You can access the cli with Docker very easy. 
![image](https://user-images.githubusercontent.com/17120076/116521851-c7969600-a8d4-11eb-8ce9-ac930a647172.png)


![Screen Shot 2021-04-29 at 09 36 36](https://user-images.githubusercontent.com/17120076/116517030-a632ab80-a8ce-11eb-9679-37e3a237103a.png)   
![Screen Shot 2021-04-29 at 09 36 46](https://user-images.githubusercontent.com/17120076/116517045-aa5ec900-a8ce-11eb-9ba8-67d3b11801b8.png)   
![Screen Shot 2021-04-29 at 09 39 45](https://user-images.githubusercontent.com/17120076/116517410-340e9680-a8cf-11eb-8d9b-5c4a3d5b0043.png)    

## How to add retention policies to your InfluxDB?
start a ssh and go to your InfluxDB.   
start the influxdb cli with:   
>influx   
>CREATE RETENTION POLICY retention_ddalert ON DDALERT DURATION 4w REPLICATION 1  

where DDALERT is the DB and DURATION the retention time.  

You can access the cli with Docker very easy. 
![image](https://user-images.githubusercontent.com/17120076/116521851-c7969600-a8d4-11eb-8ce9-ac930a647172.png)


![Screen Shot 2021-04-29 at 09 36 36](https://user-images.githubusercontent.com/17120076/116517030-a632ab80-a8ce-11eb-9679-37e3a237103a.png)    
![Screen Shot 2021-04-29 at 09 36 46](https://user-images.githubusercontent.com/17120076/116517045-aa5ec900-a8ce-11eb-9ba8-67d3b11801b8.png)      
![Screen Shot 2021-04-29 at 09 41 08](https://user-images.githubusercontent.com/17120076/116517429-3bce3b00-a8cf-11eb-9958-c8686a2ef160.png)   
![Screen Shot 2021-04-29 at 09 42 11](https://user-images.githubusercontent.com/17120076/116517437-3e309500-a8cf-11eb-8f8d-34761a0076ff.png)      


