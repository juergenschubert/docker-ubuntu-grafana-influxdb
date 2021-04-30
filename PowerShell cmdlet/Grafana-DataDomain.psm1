function Add-DDAlert2InfluxDB {
<#
.SYNOPSIS
    Get all current active alerts

.DESCRIPTION
    shows the current alerts on your DataDomain

.PARAMETER Name
    DDfqdn              DataDomain FQDN
    DDAuthTokenValue    DDAuthtoken from Connect-DD
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
    Add-DDAlert2InfluxDB  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token 
    
    Add-DDAlert2InfluxDB  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token -detailed

    Add-DDAlert2InfluxDB  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token -activealert

    Add-DDAlert2InfluxDB  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token -verbose

    Add-DDAlert2InfluxDB  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token -add2InfluxDB -InfluxDBServer 'localhost' -InfluxDB 'DDALERT' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' 

    Add-DDAlert2InfluxDB  -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DD_Token -dumpmeasurement -InfluxDBServer 'localhost' -InfluxDB 'DDALERT' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252' 

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
        [string]$InfluxDB
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
        $getalerts | ConvertTo-Json -Depth 9 | Write-Verbose

        [int]$alertno = 0
        $numberoftotalalerts = ($getalerts.alert_list.status | Measure-Object | Select-Object Count)
        #$numberoftotalalerts.Count
        foreach ($status in $getalerts.alert_list){
            Write-Verbose "Alert Status found for : $($status.status)"
            if ($status.status -eq "active") {
                    $alertno = $alertno +1
            }
        } 
        #$alertno
        if ($dumpmeasurement) {
            $InfluxMeasurement ="insert DDAlertList,DDR=""$($DDR)"",DDLocation=""$($DDLocation)"",serialno=""$($DDserialno)"" activealert=$($alertno),totalalert=$($numberoftotalalerts.Count)"
                [int64]$influxtimes = Get-Date (Get-Date).ToUniversalTime() -UFormat %s 
                [int64]$influxtime = $influxtimes * 1000000000
            write-host "$InfluxMeasurement $influxtime"
        } #End if dumpmeasurement

        If ($add2InfluxDB) {
            ####### write the data to InfluxDB
            $InfluxMeasurement ="DDAlertList,DDR=""$($DDR)"",DDLocation=""$($DDLocation)"",serialno=""$($DDserialno)"" activealert=$($alertno),totalalert=$($numberoftotalalerts.Count)"
            $body = ""
            try {
                $influxresponse = Invoke-RestMethod "http://$($InfluxDBServer):8086/query?q=SHOW DATABASES" -Method 'GET' -Headers $headers -Body $body
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
                if ( $member -eq $InfluxDB) {
                    $exist = $exist + 1
                }
            } #End foreach
            #check if the DB exist otherwise create it
            if ($exist -le 0) {
                #InfluxDB does not exist
                $body = ""
                try {
                     $influxdbcreateresponse = Invoke-RestMethod "http://$($InfluxDBServer):8086/query?q=CREATE DATABASE ""$($InfluxDB)""" -Method 'GET' -Headers $headers -Body $body
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

function  Add-DDSystemCapacity2InfluxDB {
<#
.SYNOPSIS
    Shows system level capacity statistics of your DataDomain
.DESCRIPTION
    Shows system level capacity statistics of your DataDomain
.PARAMETER Name
    DDfqdn              DataDomain FQDN
    DDAuthTokenValue    DDAuthtoken from Connect-DD
    DDTier              The DataDomain Tier you wanna show capacity. Allowed values are “active,” “cloud,” “archive,” or “total.” Default is "total"
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
    Add-DDSystemCapacity2InfluxDB -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DDtoken 

    Add-DDSystemCapacity2InfluxDB -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DDtoken -LogicalCapacity

    Add-DDSystemCapacity2InfluxDB -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DDtoken -PhysicalCapacity

    Add-DDSystemCapacity2InfluxDB -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DDtoken -DDTier 'active'

    Add-DDSystemCapacity2InfluxDB -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DDtoken -DDTier 'active' -UnitValue 'GB' 

    Add-DDSystemCapacity2InfluxDB -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DDtoken -DDTier 'active' -UnitValue 'GB' -OutputTimeFormat 'datetime'

    Add-DDSystemCapacity2InfluxDB -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DDtoken -add2InfluxDB -InfluxDBServer 'localhost' -InfluxDB 'DDSYSTEMCAPACITY' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252'

    Add-DDSystemCapacity2InfluxDB -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DDtoken -PhysicalCapacity -dumpmeasurement -add2InfluxDB -InfluxDBServer 'localhost' -InfluxDB 'DDSYSTEMCAPACITY' -DDR 'DD4200' -DDLocation 'Hamburg' -DDserialno 'CKM0013370252'
    
    Add-DDSystemCapacity2InfluxDB -DDfqdn "ddve-01.vlab.local" -DDAuthTokenValue $DDtoken -verbose 
.INPUTS
    System.String[]
.OUTPUTS
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
        [Parameter(Position=1,Mandatory=$False,HelpMessage="Access token for a DataDomain")]
        [ValidateNotNullorEmpty()]
        [ValidateLength(33,33)]
        [string]$DDAuthTokenValue,
        [Parameter()]
        [ValidateSet('active', 'cloud', 'archive', 'total')]
        [string]$DDTier = 'total',
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
        [string]$InfluxDB
    )
    begin {
        if (-not (Test-Connection -TargetName $DDfqdn -TCPPort 443 -Quiet)){
            Write-Error "Unable to connect to DataDomain: $DDfqdn." -Category ConnectionError
            exit
        }

    } #END BEGIN
    process {
        $RestUrl = $DDFqdn
        Write-Verbose "[Debug] FQDN of the DD: $DDFqdn"
        Write-Verbose "[DEBUG] token: $DDAuthTokenValue"
        Write-Verbose "[DEBUG] DDTier: $DDTier"
        $authtoken = @{
            'X-DD-AUTH-TOKEN' = $DDAuthTokenValue
        }
        try {
            $capacityresponse = Invoke-RestMethod “https://$($RestUrl):3009/rest/v2.0/dd-systems/0/stats/capacity?tier=$($DDTier)” `
            -Method GET `
            -ContentType 'application/json' `
            -Headers $authtoken `
            -ResponseHeadersVariable CapacityHeaders1 `
            -SkipCertificateCheck
        } catch {
            Write-Host "[ERROR]FAILED to fetch capaity infromation from $DDTier tier"  -fore red
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
        }
        Write-Verbose "physical capacity"
        Write-Verbose "[DEBUG] Get physical capacity metrics from DD "
        Write-Verbose "[DEBUG] Physical Capacity - response body"
        write-verbose "/rest/v2.0/dd-systems/0/stats/capacity?tier=$($DDTier) response"
        $capacityresponse | ConvertTo-Json -Depth 9 | Write-Verbose
        Write-Verbose "[DEBUG] Physical Capacity - response Header"
        $CapacityHeaders1 | ConvertTo-Json -Depth 9 | Write-Verbose

#physical capacity 
        $tblphysical = New-Object System.Data.DataTable "DataDomain physical Capacity TB"
        $colphysical1 = New-Object System.Data.DataColumn Collection_time
        $colphysical2 = New-Object System.Data.DataColumn Tier
        $colphysical3 = New-Object System.Data.DataColumn total_size_TB
        $colphysical4 = New-Object System.Data.DataColumn total_used_TB
        $colphysical5 = New-Object System.Data.DataColumn total_available_TB
        $colphysical6 = New-Object System.Data.DataColumn compression_factor

        $tblphysical.Columns.Add($colphysical1)
        $tblphysical.Columns.Add($colphysical2)
        $tblphysical.Columns.Add($colphysical3)
        $tblphysical.Columns.Add($colphysical4)
        $tblphysical.Columns.Add($colphysical5)       
        $tblphysical.Columns.Add($colphysical6)
   
        For ($i = 0; $i -lt $capacityresponse.stats_capacity.count; $i++) {
            $row = $tblphysical.NewRow()
            if ($OutputTimeFormat -eq 'datetime') {
                $row.collection_time = Get-Date -UnixTimeSeconds $capacityresponse.stats_capacity[$i].collection_epoch 
            } else {
                $row.collection_time = $capacityresponse.stats_capacity[$i].collection_epoch 
            }
            $row.Tier = $capacityresponse.stats_capacity[$i].tier_capacity_usage[0].tier
            $row.total_size_TB = [math]::Round($capacityresponse.stats_capacity[$i].tier_capacity_usage[0].physical_capacity.total / 1TB, 2)
            $row.total_available_TB = [math]::Round($capacityresponse.stats_capacity[$i].tier_capacity_usage[0].physical_capacity.available / 1TB, 2)
            $row.total_used_TB = [math]::Round($capacityresponse.stats_capacity[$i].tier_capacity_usage[0].physical_capacity.used / 1TB, 2)
            $row.compression_factor = $capacityresponse.stats_capacity[$i].tier_capacity_usage[0].compression_factor
            $tblphysical.Rows.Add($row)
        }

# logical capacity
        $tbllogical = New-Object System.Data.DataTable "DataDomain logical Capacity TB"
        $collogical1 = New-Object System.Data.DataColumn Collection_time
        $collogical2 = New-Object System.Data.DataColumn Tier
        $collogical3 = New-Object System.Data.DataColumn total_size_TB
        $collogical4 = New-Object System.Data.DataColumn total_used_TB
        $collogical5 = New-Object System.Data.DataColumn total_available_TB
        $collogical6 = New-Object System.Data.DataColumn compression_factor
        $tbllogical.Columns.Add($collogical1)
        $tbllogical.Columns.Add($collogical2)
        $tbllogical.Columns.Add($collogical3)
        $tbllogical.Columns.Add($collogical4)
        $tbllogical.Columns.Add($collogical5)       
        $tbllogical.Columns.Add($collogical6)

        For ($i = 0; $i -lt $capacityresponse.stats_capacity.count; $i++) {
            $row =  $tbllogical.NewRow()
            if ($OutputTimeFormat -eq 'datetime') {
                $row.collection_time = Get-Date -UnixTimeSeconds $capacityresponse.stats_capacity[$i].collection_epoch 
            } else {
                $row.collection_time = $capacityresponse.stats_capacity[$i].collection_epoch 
            }
            $row.Tier = $capacityresponse.stats_capacity[$i].tier_capacity_usage[0].tier
            $row.total_size_TB = [math]::Round($capacityresponse.stats_capacity[$i].tier_capacity_usage[0].logical_capacity.total / 1TB, 2)
            $row.total_available_TB = [math]::Round($capacityresponse.stats_capacity[$i].tier_capacity_usage[0].logical_capacity.available / 1TB, 2)
            $row.total_used_TB = [math]::Round($capacityresponse.stats_capacity[$i].tier_capacity_usage[0].logical_capacity.used / 1TB, 2)

            $row.compression_factor = $capacityresponse.stats_capacity[$i].tier_capacity_usage[0].compression_factor
            $tbllogical.Rows.Add($row)
        }
  
#output & Debug      
        Write-Verbose "[DEBUG] Get physical/logiccal capacity metrics from DD "
        Write-Verbose "[DEBUG] logical capacity - response body"
        $capacityresponse | ConvertTo-Json -Depth 9 | Write-Verbose
        Write-Verbose "[DEBUG] logical capacity - response Header "
        $CapacityHeaders1 | ConvertTo-Json -Depth 9 | Write-Verbose
        Write-Verbose "[DEBUG] Physical Capacity - table"
        $tblphysical | format-table | Write-Verbose
        Write-Verbose "[DEBUG] logical Capacity - table"
        $tbllogical | format-table | Write-Verbose
    #############
        #prepare the data
        #physical
        $influx_tier = ($tblphysical[0].Tier | select -last 1)
        $influx_total_size_TB = ($tblphysical[0].total_size_TB | select -last 1)
        $influx_total_size_TB = $influx_total_size_TB.Replace(',', '.');
        $influx_total_used_TB = ($tblphysical[0].total_used_TB | select -last 1)
        $influx_total_used_TB =  $influx_total_used_TB.Replace(',', '.');
        $influx_total_available_TB = ($tblphysical[0].total_available_TB | select -last 1)
        $influx_total_available_TB = $influx_total_available_TB.Replace(',', '.');
        $influx_compression_factor = ($tblphysical[0].compression_factor | select -last 1)
        $influx_compression_factor = $influx_compression_factor.Replace(',', '.');
        $InfluxMeasurementcapa ="TierCapacityUsagePhysicalCapacity,DDR=""$($DDR)"",DDLocation=""$($DDLocation)"",serialno=""$($DDserialno)"",tier=""$($influx_tier)"" PhysicalCapacityTotal=$($influx_total_size_TB),PhysicalCapacityUsed=$($influx_total_used_TB),PhysicalCapacityavailable=$($influx_total_available_TB)"
        $InfluxMeasurementdedupe ="TierCapacityUsageCompressionFactor,DDR=""$($DDR)"",DDLocation=""$($DDLocation)"",serialno=""$($DDserialno)"",tier=""$($influx_tier)"" CompressionFactor=$($influx_compression_factor)"
        #logical
        $influx_tier = ($tbllogical[0].Tier | select -last 1)
        $influx_logical_size_TB = ($tbllogical[0].total_size_TB | select -last 1)
        $influx_logical_size_TB = $influx_logical_size_TB.Replace(',', '.');
        $influx_logical_used_TB = ($tbllogical[0].total_used_TB | select -last 1)
        $influx_logical_used_TB = $influx_logical_used_TB.Replace(',', '.');
        $influx_logical_available_TB = ($tbllogical[0].total_available_TB | select -last 1) 
        $influx_logical_available_TB = $influx_logical_available_TB.Replace(',', '.');
        $InfluxMeasurementlogicalcapa ="TierCapacityUsageLogicalCapacity,DDR=""$($DDR)"",DDLocation=""$($DDLocation)"",serialno=""$($DDserialno)"",tier=""$($influx_tier)"" LogicalCapacityTotal=$($influx_logical_size_TB),LogicalCapacityUsed=$($influx_logical_used_TB),LogicalCapacityavailable=$($influx_logical_available_TB)"
# dumpmeasurement
        if ($dumpmeasurement) {

            [int64]$influxtimes = Get-Date (Get-Date).ToUniversalTime() -UFormat %s 
            [int64]$influxtime = $influxtimes * 1000000000

            #physical
            write-verbose "physical capacity"
            write-verbose "tablephysical ExandProperty"
            $tblphysical.Columns | ft -AutoSize | write-verbose
            
            write-host "$InfluxMeasurementcapa $influxtime"
            write-host "$InfluxMeasurementcapa $influxtime"
            #logical capacity
            write-verbose "logical capacity"
            write-verbose "tablephysical ExandProperty"
            $tbllogicalColumns | ft -AutoSize | write-verbose

            write-host "$InfluxMeasurementlogicalcapa $influxtime"
        } #End if dumpmeasurement
    ####### write the data to InfluxDB
        If ($add2InfluxDB) {
   
    # Let's create a timestamp
                [int64]$influxtimes = Get-Date (Get-Date).ToUniversalTime() -UFormat %s 
                [int64]$influxtime = $influxtimes * 1000000000
    # Check if the DB does exist
    # Querey the existing DBs
                $body = ""
                try {
                    $influxresponse = Invoke-RestMethod "http://$($InfluxDBServer):8086/query?q=SHOW DATABASES" -Method 'GET' -Headers $headers -Body $body
                } catch {
                    Write-Host "[ERROR]FAILED to query InfluxDB Server"  -fore red
                    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
                    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
                } #End catch
                Write-Verbose "[DEBUG][InfluxDB] InfluxDB Query existing DB $($InfluxDB) return value"
                $influxresponse  | ConvertTo-Json -Depth 9 | Write-Verbose  
    # findout if a special DB $InfluxDB is available 
                $exist=0
                foreach ($member in $influxresponse.results[0].series[0].values) {
                    if ( $member -eq $InfluxDB) {
                        $exist = $exist + 1
                    }
                } #End foreach
    # check if the DB exist otherwise create it
                if ($exist -le 0) {
    # InfluxDB does not exist - create the DB
                    $body = ""
                    try {
                        $influxdbcreateresponse = Invoke-RestMethod "http://$($InfluxDBServer):8086/query?q=CREATE DATABASE ""$($InfluxDB)""" -Method 'GET' -Headers $headers -Body $body
                    } catch {
                        Write-Host "[ERROR]FAILED to create InfluxDV $InfluxDB"  -fore red
                        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
                        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
                    } #End catch
                    Write-Verbose "[DEBUG][InfluxDB] InfluxDB created DB $InfluxDB"
                    $influxdbcreateresponse  | ConvertTo-Json -Depth 9 | Write-Verbose  
                }
   # $InfluxDB does now exist              
   ##let update the measurement
                #build header
                $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $headers.Add("Content-Type", "text/plain")
    # build body for InfluxDB
    # body for physical capa
                $bodyaddmeasurement= "$($InfluxMeasurementcapa ) $($influxtime)"
                $bodyaddmeasurement1 ="$($InfluxMeasurementdedupe) $($influxtime)"
                # write InfluxDB 
                try {
                    $influxresponse = Invoke-RestMethod "http://$($InfluxDBServer):8086/write?db=$($InfluxDB)&precision=ns" `
                    -Method POST `
                    -Headers $headersInflux `
                    -Body $bodyaddmeasurement 
                } catch {
                    Write-Host "[ERROR]FAILED to add the measurement to InfluxDB: $InfluxDB"  -fore red
                    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
                    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
                } # End Try Rest
                write-host "wrote physical capa:  $bodyaddmeasurement"
                write-host "to InfluxDB: $InfluxDB "
                              # write InfluxDB 
                try {
                    $influxresponse1 = Invoke-RestMethod "http://$($InfluxDBServer):8086/write?db=$($InfluxDB)&precision=ns" `
                    -Method POST `
                    -Headers $headersInflux `
                    -Body $bodyaddmeasurement1 
                } catch {
                    Write-Host "[ERROR]FAILED to add the measurement to InfluxDB: $InfluxDB"  -fore red
                    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
                    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
                } # End Try Rest
                write-host "wrote dedupe:  $bodyaddmeasurement1"
                write-host "to InfluxDB: $InfluxDB "

    # body for logical capa
                $bodyaddmeasurement2 = "$($InfluxMeasurementlogicalcapa) $($influxtime)"
                Write-Verbose "[DEBUG] ReST Api Body"
                Write-Verbose $bodyaddmeasurement
                # -pre8cision 'rfc3339|h|m|s|ms|u|ns'
    # write InfluxDB 
                try {
                    $influxresponse = Invoke-RestMethod "http://$($InfluxDBServer):8086/write?db=$($InfluxDB)&precision=ns" `
                    -Method POST `
                    -Headers $headersInflux `
                    -Body $bodyaddmeasurement2 
                } catch {
                    Write-Host "[ERROR]FAILED to add the measurement to InfluxDB: $InfluxDB"  -fore red
                    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
                    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
                } # End Try Rest
                write-host "wrote logical capa:  $bodyaddmeasurement2"
                write-host "to InfluxDB: $InfluxDB "
            } #End if add2InfluxDB
    } #End Process
} #End Function

function Add-InfluxDB {
<#
.SYNOPSIS
    Adds a InfluxDB on the InfluxDB Server

.DESCRIPTION
    Adds a InfluxDB on the InfluxDB Server

.PARAMETER Name
    InfluxDBServerfqdn  FQDN of the InfluxDB Server 
    DBName              Name of the InfluxDB

.PARAMETER Path
    local path

.EXAMPLE
   Add-InfluxDB  -InfluxDBServerfqdn '10.2.2.2' -DBName "influxDB" 
.INPUTS
    System.String[]

.OUTPUTS
   
.NOTES
    Author:  Juergen Schubert
    Website: http://focusarea.de
    Twitter: @NextGenBackup
#>
    [CmdletBinding()]
    param (
        [Parameter(Position=0,Mandatory=$True,HelpMessage="InfluxDB Server IP")]
        [ValidateNotNullorEmpty()]
        [string]$InfluxDBServerfqdn,
        [Parameter(Position=1,Mandatory=$False,HelpMessage="Database Name")]
        [ValidateNotNullorEmpty()]
        [string]$DBName
    )
    begin {
            if (-not (Test-Connection -TargetName $InfluxDBServerfqdn -TCPPort 22 -Quiet)){
                Write-Error "Unable to connect to InfluxDB Server: $InfluxDBServerfqdn." -Category ConnectionError
                exit
               } #End IF
    } #END BEGIN

    process {
        $RestUrl = $DDfqdn
        Write-Verbose "[Debug] FQDN of the of InfluxDB"
        Write-Verbose "$InfluxDBServerfqdn"
        Write-Verbose "[DEBUG] DataBase Name"
        Write-Verbose $DBName

        $headersInflux = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headersInflux.Add("Content-Type", "application/x-www-form-urlencoded")

        $bodyinfluxcreatedb = "q=CREATE%20DATABASE%20$($DBName)"
        Write-Verbose "[DEBUG] ReST Api Body"
        Write-Verbose $bodyinfluxcreatedb

        try {
            $influxresponse = Invoke-RestMethod "http://$($InfluxDBServerfqdn):8086/query" `
            -Method POST `
            -Headers $headersInflux `
            -Body $bodyinfluxcreatedb 
        } catch {
            Write-Host "[ERROR]FAILED to create the InfluxDB DB $DBName"  -fore red
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
        }
        Write-Verbose "[DEBUG] Added $DBName Database"
        Write-Verbose "[DEBUG] response body"
        Write-Host "InfluxDB: $DBName in InfluxDBServer: $InfluxDBServerfqdn successfull added"
        $influxresponse  | ConvertTo-Json -Depth 9 | Write-Verbose 
    } #End Process
} #End Function

function Add-InfluxMeasurement {
<#
.SYNOPSIS
    Adds a Measurement to a existing Influx DB

.DESCRIPTION
    Adds a Measurement to a existing Influx DB
    
.PARAMETER Name
    InfluxDBServerfqdn  FQDN of the InfluxDB Server 
    DBName              Name of the InfluxDB
    Measurement         Measurement string with Tags and Fields
    timestamp           timestamp in ns

.PARAMETER Path
    local path

.EXAMPLE
   Add-InfluxMeasurement  -InfluxDBServerfqdn '10.2.2.2' -DBName "influxDB" -Measurement "ClearedAlertCount,DDR="DD4200",location="Hamburg",serialno="CKM00133702521" ErrorCount=20" -timestamp 1619100566000000000
.INPUTS
    System.String[]

.OUTPUTS
   
.NOTES
    Author:  Juergen Schubert
    Website: http://focusarea.de
    Twitter: @NextGenBackup
#>
    [CmdletBinding()]
    param (
        [Parameter(Position=0,Mandatory=$True,HelpMessage="InfluxDB Server IP")]
        [ValidateNotNullorEmpty()]
        [string]$InfluxDBServerfqdn,
        [Parameter(Position=1,Mandatory=$False,HelpMessage="Database Name")]
        [ValidateNotNullorEmpty()]
        [string]$DBName,
        [Parameter(Position=2,Mandatory=$False,HelpMessage="Influx Measurement you wanna add")]
        [ValidateNotNullorEmpty()]
        [string]$Measurement,
        [Parameter(Position=4,Mandatory=$False,HelpMessage="Timestamp for the measurement in Unix Time seconds")]
        [string]$timestamp
        )
    begin {
            if (-not (Test-Connection -TargetName $InfluxDBServerfqdn -TCPPort 22 -Quiet)){
                Write-Error "Unable to connect to InfluxDB Server: $InfluxDBServerfqdn." -Category ConnectionError
                exit
               } #End IF
    } #END BEGIN

    process {
        $RestUrl = $DDfqdn
        Write-Verbose "[Debug] FQDN of the of InfluxDB"
        Write-Verbose "$InfluxDBServerfqdn"
        Write-Verbose "[DEBUG] DataBase Name"
        Write-Verbose $DBName
        Write-Verbose "[DEBUG] ###############"
        Write-Verbose "[DEBUG] measurement"
        Write-Verbose $Measurement
        Write-Verbose "[DEBUG] timestamp"
        Write-Verbose $timestamp

        if (!$timestamp) {
            #create epoch seconds
            $timestamp = Get-Date (Get-Date).ToUniversalTime() -UFormat %s
        }

        $headersInflux = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headersInflux.Add("Content-Type", "application/x-www-form-urlencoded")

        $bodyaddmeasurement = "$($Measurement)"
        Write-Verbose "[DEBUG] ReST Api Body"
        Write-Verbose $bodyaddmeasurement
# -precision 'rfc3339|h|m|s|ms|u|ns'
        try {
            $influxresponse = Invoke-RestMethod "http://$($InfluxDBServerfqdn):8086/write?db=$($DBName)&precision=s" `
            -Method POST `
            -Headers $headersInflux `
            -Body $bodyaddmeasurement 
        } catch {
            Write-Host "[ERROR]FAILED to add the measurement to InfluxDB: $DBName"  -fore red
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red
        }
        Write-Verbose "[DEBUG] Added $DBName Database"
        Write-Verbose "[DEBUG] response body"
        Write-Verbose "Influx measurement: $Measurement on InfluxDBServer: $InfluxDBServerfqdn in InfluxDB: $DBName successfull added"
        $influxresponse  | ConvertTo-Json -Depth 9 | Write-Verbose 



    } #End Process
} #End Function

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
        if ($PSVersionTable.PSEdition -eq "Desktop") {
                 Write-Error "This has not been tested with PoweShell Desktop version" -Category ConnectionError -ErrorAction Stop
                } 
        if (!$noconnectcheck) {
            if ($PSVersionTable.PSEdition -eq "Core") { 
                if (-not (Test-Connection -TargetName $DDfqdn -TCPPort 443 -Quiet)){
                    Write-Error "Unable to connect to DataDomain: $DDfqdn." -Category ConnectionError -ErrorAction Stop
                   } #End Test-Connection
            } #End $PSVersionTable.PSEdition
        } #End noconnectcheck
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
            Write-Host "[ERROR]FAILED to fetch auth token from $RestUrl with ReST Call"  -fore red
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__   -fore red
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription  -fore red -ErrorAction Stop
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

