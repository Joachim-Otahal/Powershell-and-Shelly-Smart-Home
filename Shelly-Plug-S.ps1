# These useful for Shelly Plug S Plus and for Shelly Plug S
# I recommend using it in Powershell-ISE, which is available on all Windows installations.
# Joachim Otahal 2024-05


# Where is the device ?
$ShellyPlugIP="192.168.33.194"

# Helper function to list all properties
function Get-PropertiesRecursive {
    param (
        [Parameter(ValueFromPipeline)][object]$InputObject,
        [String]$ParentName
    )
    if ($ParentName) {$ParentName +="."}
    foreach ($Property in $InputObject.psobject.Properties) {
        # This puts special characters in '' like you need it when using it directly with powershell
        if ($Property.Name -like "*:*" -or $Property.Name -like "* *"  -or $Property.Name -like "*-*") {
            $Name = "'$($Property.Name)'"
        } else {
            $Name = $Property.Name
        }
        $PropertyTypeName = $Property.TypeNameOfValue.Split('.')[-1]
        if (($PropertyTypeName -ne "PSCustomObject" -and $PropertyTypeName -notlike "Object*") -or
            $ParentName -like "*.SyncRoot.*") {
            [pscustomobject]@{
                TypeName = $Property.TypeNameOfValue.Split(".")[-1]
                Property = "$ParentName$Name"
                Value = $Property.Value
            }
        } else {
            Get-PropertiesRecursive $Property.Value -ParentName "$ParentName$Name"
        }
    }
}


# List all available rpc commands for this device (Only Shelly Plug S Plus)
(((Invoke-WebRequest -Uri "http://$ShellyPlugIP/rpc/Shelly.ListMethods" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json).methods


# Get the status (Only Shelly Plug S Plus)
$ShellyPlugGetStatus = ((Invoke-WebRequest -Uri "http://$ShellyPlugIP/rpc/Shelly.GetStatus" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json

# List all status information in a readable way.
Get-PropertiesRecursive $ShellyPlugGetStatus -ParentName '$ShellyPlugGetStatus'


# Switch on (Only Shelly Plug S Plus). In this variant we get the information whether the switch was on before sending the command. This way the script can see whether the status actually changed.
$ShellyPlugSwitch = ((Invoke-WebRequest -Uri "http://$ShellyPlugIP/rpc/Switch.Set?id=0&on=true" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
$ShellyPlugSwitch.was_on
# Switch off (Only Shelly Plug S Plus)
$ShellyPlugSwitch = ((Invoke-WebRequest -Uri "http://$ShellyPlugIP/rpc/Switch.Set?id=0&on=false" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
$ShellyPlugSwitch.was_on


# Get relay status old-style. Works on both Shelly Plug S and Shelly Plug S Plus
$ShellyPlugSwitch = ((Invoke-WebRequest -Uri "http://$ShellyPlugIP/relay/0" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
$ShellyPlugSwitch.ison


# Switch old-style. Works on both Shelly Plug S and Shelly Plug S Plus
$ShellyPlugSwitch = ((Invoke-WebRequest -Uri "http://$ShellyPlugIP/relay/0?turn=on" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
$ShellyPlugSwitch.ison
$ShellyPlugSwitch = ((Invoke-WebRequest -Uri "http://$ShellyPlugIP/relay/0?turn=off" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
$ShellyPlugSwitch.ison


# Get the full status from Shelly Plug S (gen 1). Tested since a friend lent me one for tests. Does not work on Shelly Plug S Plus
$ShellyPlugGetStatus = ((Invoke-WebRequest -Uri "http://$ShellyPlugIP/status" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json

# List all status information in a readable way.
Get-PropertiesRecursive $ShellyMiniGetStatus -ParentName '$ShellyMiniGetStatus'
