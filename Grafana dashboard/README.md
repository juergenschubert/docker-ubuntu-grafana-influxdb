This is the documentation how to import the Dashboard.

As of today there are two types of Dashboards
DataDomain - Streaming Demo  
   - This is a full blown dashboard with streming data and not need to connect to a DD. For Demo purpose only
DataDomain
   - This is the Dashboard you should use for visualize your DD data. 

Please make sure that you create bost folder in Granfa with the same name as some references are not dynamic, just bound to a serach a folder name.

# Steps to create the folder structure  
### Go to manage your dashboard  
![Screen Shot 2021-04-29 at 08 09 29](https://user-images.githubusercontent.com/17120076/116508774-5c43c880-a8c2-11eb-9d6e-16bd5147c702.png)

#### Click on New Folder  
![Screen Shot 2021-04-29 at 08 11 21](https://user-images.githubusercontent.com/17120076/116508855-86958600-a8c2-11eb-8410-73ab31e0a287.png)

### Name the folder like DataDomain or DataDomain - Streaming Demo  
![Screen Shot 2021-04-29 at 08 11 56](https://user-images.githubusercontent.com/17120076/116508911-a0cf6400-a8c2-11eb-8172-e02f03cba08c.png)

# Steps to import and move the Grafana Dashbords
make sure you have downloaded both folder inside **Grafana dashboard** and the dashboard inside the folder.  
Folder are DataDomain and DataDomain - Streaming Demo. 

### Import the dashboard
Got to **manage dashboard**.   
![Screen Shot 2021-04-29 at 08 09 29](https://user-images.githubusercontent.com/17120076/116509280-500c3b00-a8c3-11eb-872f-a005ae21aa1d.png)

Click on import.  
![Screen Shot 2021-04-29 at 08 17 28](https://user-images.githubusercontent.com/17120076/116509324-60241a80-a8c3-11eb-9478-e14c76b35840.png)

uplad JSON file.  
![Screen Shot 2021-04-29 at 08 18 09](https://user-images.githubusercontent.com/17120076/116509389-7a5df880-a8c3-11eb-8df4-bbdc2d4c9c18.png)

Choose the right JSON file.    
![Screen Shot 2021-04-29 at 08 19 25](https://user-images.githubusercontent.com/17120076/116509472-a5e0e300-a8c3-11eb-828f-52aef2a5f6f9.png)

Change / blank the uid and choose the folder - hit 
![Screen Shot 2021-04-29 at 08 20 36](https://user-images.githubusercontent.com/17120076/116509574-d9237200-a8c3-11eb-8ac1-6efbf177261e.png)

Make sure you have choose the right folder to place the dashboard and wiped out the uid.   
![Screen Shot 2021-04-29 at 08 20 47](https://user-images.githubusercontent.com/17120076/116509580-dcb6f900-a8c3-11eb-8f94-5e3945241077.png)

you should see the dashboard 
#let's add the datasource
navigate to the Data Sources   
![Screen Shot 2021-04-29 at 08 24 36](https://user-images.githubusercontent.com/17120076/116510127-b6458d80-a8c4-11eb-9267-5ac204ea66fb.png)

Add a data source
![Screen Shot 2021-04-29 at 08 24 53](https://user-images.githubusercontent.com/17120076/116510149-bfcef580-a8c4-11eb-975c-ae250b21674c.png)

Search for Influxdb
![Screen Shot 2021-04-29 at 08 25 03](https://user-images.githubusercontent.com/17120076/116510181-ca898a80-a8c4-11eb-97cb-1db4284367d1.png)
click on the datasource

Add configuration and watch out that the very first time InfluxDB does not have DDALERT or any other DB available. So the add will fail

![Screen Shot 2021-04-29 at 08 29 28](https://user-images.githubusercontent.com/17120076/116510331-0ae90880-a8c5-11eb-99fc-6315989df5b6.png)

Configure the HTTP information to localhost:8086
![Screen Shot 2021-04-29 at 08 25 38](https://user-images.githubusercontent.com/17120076/116510410-26ecaa00-a8c5-11eb-9046-2ea3b7b32c4f.png)

Configure the InfluxDB details as user and database. As the DB you are choosing does not exist this will fail !!!
![Screen Shot 2021-04-29 at 08 26 40](https://user-images.githubusercontent.com/17120076/116510497-4e437700-a8c5-11eb-8202-e5bf89b97570.png)
![Screen Shot 2021-04-29 at 08 25 57](https://user-images.githubusercontent.com/17120076/116510519-53a0c180-a8c5-11eb-9a15-7765aa85c724.png)
![Screen Shot 2021-04-29 at 08 32 18](https://user-images.githubusercontent.com/17120076/116510588-6fa46300-a8c5-11eb-9dc4-0581d9a69a67.png)
