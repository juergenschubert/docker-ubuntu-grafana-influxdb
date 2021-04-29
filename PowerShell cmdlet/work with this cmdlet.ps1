 _____            __                                       _ _      _                            
/ ____|          / _|                                     | | |    | |                           
| |  __ _ __ __ _| |_ __ _ _ __   __ _    ___ _ __ ___   __| | | ___| |_     ___ _   _ _ __   ___ 
| | |_ | '__/ _` |  _/ _` | '_ \ / _` |  / __| '_ ` _ \ / _` | |/ _ \ __|   / __| | | | '_ \ / __|
| |__| | | | (_| | || (_| | | | | (_| | | (__| | | | | | (_| | |  __/ |_    \__ \ |_| | | | | (__ 
\_____|_|  \__,_|_| \__,_|_| |_|\__,_|  \___|_| |_| |_|\__,_|_|\___|\__|   |___/\__, |_| |_|\___|
                                                                                 __/ |           
                                                                                |___/            
                                                                                
$function_path = '/Users/juergen/Documents/DPSCodeAcademy/PowerShell/#dev/DataDomain/function'
$ModuleName = 'Grafana-DataDomain'
$NewModule_path = '/Users/juergen/Documents/DPSCodeAcademy/Projekte/Grafana - DD/PowerShellCmdlet'
$new_function_path = '/Users/juergen/Documents/DPSCodeAcademy/Projekte/Grafana - DD/PowerShellFunction'
$functionToBeCopied = @('function-Connect-DD-JS.ps1','function-Get-DDAlert-JS.ps1')
$Newcmdllocation = '/Users/juergen/Documents/DPSCodeAcademy/GitHub/docker-ubuntu-grafana-influxdb/PowerShell cmdlet'
                                                                             
Get-ChildItem $function_path



                                                                                # create a Grafana cmdlet to github Grafana
# copy the needed function to GitHub for the Grafana cmdlet
foreach ($file in $functionToBeCopied) {
    Copy-Item -Path $function_path/$file -Destination $new_function_path/$file -force
}

Get-ChildItem $new_function_path -Include '*.ps1' -rec | ForEach-Object {gc $_; ""} | out-file "$($NewModule_path)/$($ModuleName).psm1" -force

Copy-Item -Path $NewModule_path/*.* -Destination $Newcmdllocation -force

Get-ChildItem $new_function_path 
Get-ChildItem $NewModule_path