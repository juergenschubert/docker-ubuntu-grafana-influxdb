

The Dashboard showing some Information of your DD. 
![DDGrafana-dashboard](https://user-images.githubusercontent.com/17120076/116391028-f5210800-a81e-11eb-923c-2f649867e92e.gif). 

Visualize the DD Alerts of your DataDomain.   
![DDGrafana-Alert](https://user-images.githubusercontent.com/17120076/116391246-32859580-a81f-11eb-8d0f-ca799d2c55ca.gif). 

Visualize the capacity of your DataDomain.  
![DDGrafana-capacity](https://user-images.githubusercontent.com/17120076/116391358-5943cc00-a81f-11eb-8bc3-5bd4878a1625.gif). 

Visualize the streams of your DataDomain
![DDGrafana-streams](https://user-images.githubusercontent.com/17120076/116391883-01f22b80-a820-11eb-95f5-e02b007dd085.gif). 

# How can you archive these nice Grafana dashboards in your environment?   

I am using a Docker image with **Grafana** and **InfluxDB** which is:    
https://hub.docker.com/r/philhawthorne/docker-influxdb-grafana/     
You find how to start and how to use on his page.

**Why Grafana and InfluxDB**? Because this is a easy way to viualize the content of a time series DB InfluxDB which got their series data from **YOUR** DataDomain.  
The highlevel concept is to deploy Grafana and InfluxDB either on Linux or with docker, import the DataDomain Grafana dashboards and use the **PowerShell cmdlet** to get live data from your DataDomain into InfluxDB which is the datasource for Grafana. This can be automated so you get automated these udates and your Grafan will also show history. **BUT** watchout as data will grow to either delete old series or use [InfluxDB retention policies](https://docs.influxdata.com/influxdb/v1.8/guides/downsample_and_retain/)
The folder in this github repo will conatain the following information.   
## Grafana and InfluxDB  
This will contain the docker file if you wanna create your own instead of consuming https://hub.docker.com/r/philhawthorne/docker-influxdb-grafana/.                   
## Grafana dashboard  
Here you do find the latest and greatest Grafana dashboard. 

## PowerShell cmdlet  
Here you do find the latest PowerShell cndlet which will query the DD and publish the result to InfluxDB.             

**More will come and I am happy to get "requests" **



