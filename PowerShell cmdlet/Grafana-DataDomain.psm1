function Connect-DD {
    <#
.SYNOPSIS
    Connect to a DataDomain you specify and returns the authtoken for further login

.DESCRIPTION
    Connect-DD is a function which logs into a DataDomain with sysadmin and password
    and returns the authtoken which can be used for other ReST api call.

.PARAMETER Name
    DDfqdn        DataDomain FQDN
    DDUserName    User Name for DD
    DDPassword    Password for this user
    noconcheck    switches off the connection test if DD is reachable via ping

.PARAMETER Path
    local path

.EXAMPLE
    Connect-DD -DDfqdn "ddve-01" -DDUserName "sysadmin" -DDPassword "changeme"

    $DDtoken = Connect-DD -DDfqdn "ddve-01" -DDUserName "sysadmin" -DDPassword "changeme"

    Connect-DD -DDfqdn "ddve-01" -DDUserName "sysadmin" -DDPassword "changeme" -verbose

    Connect-DD -DDfqdn "ddve-01" -DDUserName "sysadmin" -DDPassword "changeme" -$noconnectcheck

.INPUTS
    System.String[]

.OUTPUTS
    DataDomain Auth Token

.NOTES
    Author:  Juergen Schubert
    Website: http://focusarea.de
    Twitter: @NextGenBackup
#>
    [CmdletBinding()]
    param (
        [Parameter(Position=0,Mandatory=$True,HelpMessage="FQDN or IP address of your DataDomain system.")]
        [ValidateNotNullorEmpty()]
        [string]$DDfqdn,
        [Parameter(Position=1,Mandatory=$False,HelpMessage="System Admin login name on your DataDomain. You can use sysadmin.")]
        [ValidateNotNullorEmpty()]
        [string]$DDUserName = 'sysadmin',
        [Parameter(Position=2,Mandatory=$False,HelpMessage="Please provide a valid password for your user!")]
        [ValidateNotNullorEmpty()]
        [string]$DDPassword = 'Password123!',
        [Parameter(Mandatory=$false)]
        [Switch]$noconnectcheck
    )

    begin {
        if ($PSVersionTable.PSEdition -ne "Core") {
            Write-Error "This function has only be tested with PowerShell Core" -Category ConnectionError -ErrorAction Stop
        }

        if (!$noconnectcheck) {
            if (-not (Test-Connection -TargetName $DDfqdn -TCPPort 443 -Quiet)){
                Write-Error "Unable to connect to DataDomain: $DDfqdn." -Category ConnectionError
               }
        }
    } #END BEGIN

    process {
        $RestUrl = $DDfqdn

        $auth = @{
            username = "$($DDUserName)"
            password = "$($DDPassword)"
        }

        Write-Verbose "[DD] Username: $DDUserName"
        Write-Verbose "[DD] Password: $DDPassword"

        Write-Verbose "[DD] Login to get the access token" -InformationAction Continue
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Write-Verbose "[DD] FQDN $DDfqdn"
        #LOGIN TO DD REST API
        Write-Verbose "[DD] Login to get the access token"
           try {
            $response = Invoke-RestMethod -uri "https://$($RestUrl):3009/rest/v1.0/auth" `
            -Method 'POST' `
            -ContentType 'application/json' `
            -Body (ConvertTo-Json $auth) `
            -SkipCertificateCheck `
            -ResponseHeadersVariable Headers
        } catch {

            Write-Host "[ERROR]FAILED to fetch auth token from $RestUrl"  -fore red
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
        }
        $DDAutoTokenValue = $Headers['X-DD-AUTH-TOKEN'][0]
        $mytoken = @{
            'X-DD-AUTH-TOKEN' = $Headers['X-DD-AUTH-TOKEN'][0]
        }
        Write-Verbose "[DEBUG] X-DD-Auth-Token"
        Write-Verbose "$Headers['X-DD-AUTH-TOKEN']"
        Write-Verbose "[DEBUG] token"
        Write-Verbose $mytoken
        Write-Verbose "[DEBUG] response body JSON"
        Write-Verbose $response | ConvertTo-Json
        Write-Verbose "[DEBUG] response body"
        $response | ConvertTo-Json | Write-Verbose 
        Write-Verbose "[DEBUG] response Header"
        $Headers | ConvertTo-Json -Depth 9 | Write-Verbose 
        $global:DDAuthToken = $mytoken
        $measureObject = $DDAutoTokenValue | Measure-Object -Character;
        $counttokenchar = $measureObject.Character;

        return $DDAutoTokenValue

    } # END Process
} #END Function

function Get-DDAlert {
<#
.SYNOPSIS
    Get all current active alerts

.DESCRIPTION
    shows the current alerts on your DataDomain

.PARAMETER Name
    DDfqdn              DataDomain FQDN
    DDAuthTokenValue    DDAuthtoken from Connect-DD
    detailed            Return a details alert report
    totalalert          Returns the value of the number of total alerts
    activealert         Return the number of active alerts only
    add2InfluxDB        Add the active alert no and alert list to a InfluxDB for grafana reproting
    dumpmeasurement     dup the Influx measurement to the stdout for uploading from the cli
    InfluxDB            InfluxDB servername or IP
    InfluxDBServer      InfluxDB database to which the measurement will be added to
    DDR                 DataDomain Restorer typ i.e. DD4200
    DDLocation          Location where you can find this DD i.e. Hamburg
    DDserialno          Serialnumber of this DataDomain i.e CKM0013370000

.PARAMETER Path
    local path

.EXAMPLE
    Get-DDAlert  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token 
    
    Get-DDAlert  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token -detailed

    Get-DDAlert  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token -activealert

    Get-DDAlert  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token -verbose

    Get-DDAlert  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token -add2InfluxDB -InfluxDBServer 'localhost' -InfluxDB 'DDALERT' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' 

    Get-DDAlert  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token -dumpmeasurement -InfluxDBServer 'localhost' -InfluxDB 'DDALERT' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' 

.INPUTS
    ReturnValue 'detailed','activealert','severity'

.OUTPUTS
   
.NOTES
    Author:  Juergen Schubert
    Website: http://focusarea.de
    Twitter: @NextGenBackup
#>
    [CmdletBinding()]
    param (
        [Parameter(Position=0,Mandatory=$True,HelpMessage="FQDN or Ip of your DataDomain system.")]
        [ValidateNotNullorEmpty()]
        [string]$DDfqdn,
        [Parameter(Position=1,Mandatory=$False,HelpMessage="Access token for a DataDomain")]
        [ValidateNotNullorEmpty()]
        [ValidateLength(33,33)]
        [string]$DDAuthTokenValue,
        [Parameter(Mandatory=$false,HelpMessage="Returns detailed alert statics in json format")]
        [Switch]$detailed,
        [Parameter(Mandatory=$false,HelpMessage="Returns only the number of active alerts.")]
        [Switch]$activealert,
        [Parameter(Mandatory=$false,HelpMessage="Returns only the number of total alerts.")]
        [Switch]$totalalert,
        [Parameter(Mandatory=$false,HelpMessage="Enable write to the InfluxDB.")]
        [Switch]$add2InfluxDB,
        [Parameter(Mandatory=$false,HelpMessage="Enable a dump of the InfluxDB measurement to standardout.")]
        [Switch]$dumpmeasurement,
        [Parameter(Mandatory=$false,HelpMessage="DataDomain System type i.e.DD4200.")]
        [ValidateNotNullorEmpty()]
        [string]$DDR,
        [Parameter(Mandatory=$false,HelpMessage="Location of the DDR  i.e. Hamburg.")]
        [ValidateNotNullorEmpty()]
        [string]$DDLocation,
        [Parameter(Mandatory=$false,HelpMessage="Serial number of the DD i.e. CKM00133702521.")]
        [ValidateNotNullorEmpty()]
        [string]$DDserialno,
        [Parameter(Mandatory=$false,HelpMessage="FQDN or IP of the InfluxDB Server.")]
        [ValidateNotNullorEmpty()]
        [string]$InfluxDBServer,
        [Parameter(Mandatory=$false,HelpMessage="Influx database name for that measurement.")]
        [ValidateNotNullorEmpty()]
        [string]$InfluxDB,
        [Parameter(Mandatory=$false,HelpMessage="timestamp in Unix/epoch time for measurement entry into Influx.")]
        [Switch]$epochtime
    )
    begin {
        if ($PSVersionTable.PSEdition -ne "Core") {
            Write-Error "This function has only be tested with PowerShell Core" -Category ConnectionError -ErrorAction Stop       }
        if (-not (Test-Connection -TargetName $DDfqdn -TCPPort 443 -Quiet)){
            Write-Error "Unable to connect to DataDomain: $DDfqdn." -Category ConnectionError
            exit
        }
    } #END BEGIN

    process {
        $RestUrl = $DDfqdn
        Write-Verbose "[Debug] FQDN of the DD"
        Write-Verbose "$DDfqdn"
        Write-Verbose "[DEBUG] token"
        Write-Verbose $DDAuthTokenValue

        $authtoken = @{
            'X-DD-AUTH-TOKEN' = $DDAuthTokenValue
        }
        try {
            $getalerts = Invoke-RestMethod “https://$($RestUrl):3009/rest/v1.0/dd-systems/0/alerts” `
            -Method GET `
            -ContentType 'application/json' `
            -Headers $authtoken `
            -SkipCertificateCheck


        } catch {
            Write-Host "[ERROR]FAILED to fetch alerts from $RestUrl"  -fore red
            Write-Host "Try to renew your DDtoken with Connect-DD." -fore green
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
        }
        Write-Verbose "[DEBUG] Get all alerts from DD"
        Write-Verbose "[DEBUG] response body"
#        $getalerts | Format-Table | Write-Verbose
        $getalerts | ConvertTo-Json -Depth 9 | Write-Verbose

        [int]$alertno = 0
        $numberoftotalalerts = ($getalerts.alert_list.status | Measure-Object | Select-Object Count)

        foreach ($status in $getalerts.alert_list){
            Write-Verbose "Alert Status found for : $($status.status)"
            if ($status.status -eq "active") {
                    $alertno = $alertno +1
            }
        }
#see what you need to get returned
        if ($detailed){
            $getalerts | ConvertTo-Json -Depth 9
        }
        if ($totalalert) {
            $numberoftotalalerts.Count
        }
        if ($activealert) {
            write-host $alertno
        }

        if ($dumpmeasurement) {
            $InfluxMeasurement ="insert DDAlertList,DDR=""$($DDR)"",DDLocation=""$($DDLocation)"",serialno=""$($DDserialno)"" activealert=$($alertno),totalalert=$($numberoftotalalerts.Count)"
#            if (!$epochtime) {
#                #create epoch nano seconds
                [int64]$influxtimes = Get-Date (Get-Date).ToUniversalTime() -UFormat %s 
                [int64]$influxtime = $influxtimes * 1000000000
                #            } else {
#                [int]$influxtime = $epochtime
#            }
            write-host "$InfluxMeasurement $influxtime"

        } #End if dumpmeasurement
        If ($add2InfluxDB) {
            ####### write the data to InfluxDB
#            $InfluxDBServer = 'localhost'
#            $InfluxDB = 'DDALERT'
            $InfluxMeasurement ="DDAlertList,DDR=""$($DDR)"",DDLocation=""$($DDLocation)"",serialno=""$($DDserialno)"" activealert=$($alertno),totalalert=$($numberoftotalalerts.Count)"
#            if (!$epochtime) {

#create epoch seconds
#                $influxtime = Get-Date (Get-Date).ToUniversalTime() -UFormat %s
#            } else {
#                [int]$influxtime = $epochtime
#            }
# Check if the DB does exist
             $body = ""
             try {
                $influxresponse = Invoke-RestMethod 'http://localhost:8086/query?q=SHOW DATABASES' -Method 'GET' -Headers $headers -Body $body
            } catch {
                Write-Host "[ERROR]FAILED to query InfluxDB Server"  -fore red
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
            } #End catch
            Write-Verbose "[DEBUG][InfluxDB][174] InfluxDB Query existing DB return value"
            $influxresponse  | ConvertTo-Json -Depth 9 | Write-Verbose  
            #findout if a special DB is available 
            $exist=0
            foreach ($member in $influxresponse.results[0].series[0].values) {
                if ( $member -eq $args[0]) {
                    $exist = $exist + 1
                }
            } #End foreach
            #check if the DB exist otherwise create it
            if ($exist -le 0) {
                #InfluxDB does not exist
                $body = ""
                try {
                     $influxdbcreateresponse = Invoke-RestMethod "http://localhost:8086/query?q=CREATE DATABASE ""$($InfluxDB)""" -Method 'GET' -Headers $headers -Body $body
                } catch {
                    Write-Host "[ERROR]FAILED to create InfluxDV $InfluxDB"  -fore red
                    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
                    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
                } #End catch
                Write-Verbose "[DEBUG][InfluxDB] InfluxDB created DB $InfluxDB"
                $influxdbcreateresponse  | ConvertTo-Json -Depth 9 | Write-Verbose  
            }

            $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $headers.Add("Content-Type", "text/plain")
            $bodyaddmeasurement = "$($InfluxMeasurement) $($influxtime)"
            Write-Verbose "[DEBUG] ReST Api Body"
            Write-Verbose $bodyaddmeasurement
            # -pre8cision 'rfc3339|h|m|s|ms|u|ns'
            try {
                $influxresponse = Invoke-RestMethod "http://$($InfluxDBServer):8086/write?db=$($InfluxDB)&precision=s" `
                -Method POST `
                -Headers $headersInflux `
                -Body $bodyaddmeasurement 
            } catch {
                Write-Host "[ERROR]FAILED to add the measurement to InfluxDB: $InfluxDB"  -fore red
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
            } # End Try Rest
            write-host "wrote:  $bodyaddmeasurement"
            write-host "to InfluxDB: $InfluxDB "
} #End if add2InfluxDB

    
    } #End process
    end {} #End end block
} #End Function

