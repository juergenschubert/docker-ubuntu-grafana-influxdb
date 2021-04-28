I am using a Docker file with Grafana and InfluxDB which is:  
https://hub.docker.com/r/philhawthorne/docker-influxdb-grafana/  
You find how to start and how to use on his page

The Dashboard showing some Information of your DD. 
![DDGrafana-dashboard](https://user-images.githubusercontent.com/17120076/116391028-f5210800-a81e-11eb-923c-2f649867e92e.gif). 

Visualize the DD Alerts of your DataDomain.   
![DDGrafana-Alert](https://user-images.githubusercontent.com/17120076/116391246-32859580-a81f-11eb-8d0f-ca799d2c55ca.gif). 

Visualize the capacity of your DataDomain.  
![DDGrafana-capacity](https://user-images.githubusercontent.com/17120076/116391358-5943cc00-a81f-11eb-8bc3-5bd4878a1625.gif). 

Visualize the streams of your DataDomain.
![DDGrafana-streams](https://user-images.githubusercontent.com/17120076/116391883-01f22b80-a820-11eb-95f5-e02b007dd085.gif). 

More will come and I am happy to get "requests"

To get the first Dashboard imported for the DataDomain Dashboard move on the the Grafa directory and import the json files from there. 

PowerShell scripts / cmdlet will be created and used to fill in the needed information into InfluxDB so adding it to a cron can make the automation for data retrival perfect.  

