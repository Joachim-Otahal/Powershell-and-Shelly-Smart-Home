# These useful for Shelly 1 Mini Gen 3
# I recommend using it in Powershell-ISE, which is available on all Windows installations.
# Joachim Otahal 2024-05


# Where is the device ?
$ShellyMini = "192.168.33.191"

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


# List all available rpc commands for this device
(((Invoke-WebRequest -Uri "http://$ShellyMini/rpc/Shelly.ListMethods" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json).methods


# Get the status
$ShellyMiniGetStatus = ((Invoke-WebRequest -Uri "http://$ShellyMini/rpc/Shelly.GetStatus" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
# Selected infos, here switch status and temperature.
$ShellyMiniGetStatus.'switch:0'.output
$ShellyMiniGetStatus.'switch:0'.temperature.tC

# List all status information in a readable way.
Get-PropertiesRecursive $ShellyMiniGetStatus -ParentName '$ShellyMiniGetStatus'


# Get the configuration
$ShellyMiniGetConfig = ((Invoke-WebRequest -Uri "http://$ShellyMini/rpc/Shelly.GetConfig" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json

# List all config information in a readable way.
Get-PropertiesRecursive $ShellyMiniGetConfig -ParentName '$ShellyMiniGetConfig'


# Configure Switch to "on by default" nach Power-Loss
Invoke-WebRequest -Uri 'http://$ShellyMini/rpc/Switch.SetConfig?id=0&config={"initial_state":"on"}' -Method Get -UseBasicParsing -TimeoutSec 5
# Configure Switch name
Invoke-WebRequest -Uri 'http://$ShellyMini/rpc/Switch.SetConfig?id=0&config={"name":"SwitchBoiler"}' -Method Get -UseBasicParsing -TimeoutSec 5


# Switch on. In this variant we get the information whether the switch was on before sending the command. This way the script can see whether the status actually changed.
$ShellyMiniSwitch = ((Invoke-WebRequest -Uri "http://$ShellyMini/rpc/Switch.Set?id=0&on=true" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
$ShellyMiniSwitch.was_on
# Switch off
$ShellyMiniSwitch = ((Invoke-WebRequest -Uri "http://$ShellyMini/rpc/Switch.Set?id=0&on=false" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
$ShellyMiniSwitch.was_on


# Status as Gen 1 command. Untested since I don't have one, "Not found" on Gen 3
$ShellyMiniGetStatus = ((Invoke-WebRequest -Uri "http://$ShellyMini/status" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json

# List all Gen1 status information in a readable way.
Get-PropertiesRecursive $ShellyMiniGetStatus -ParentName '$ShellyMiniGetStatus'

# Get relay status as Gen 1 command. Works for Gen3 too.
$ShellyMiniSwitch = ((Invoke-WebRequest -Uri "http://$ShellyMini/relay/0" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
$ShellyMiniSwitch.ison

# Switch on in "Gen 1 command" style, which work on Gen3 too. This time it returns the status after the switching.
$ShellyMiniSwitch = ((Invoke-WebRequest -Uri "http://$ShellyMini/relay/0?turn=on" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
$ShellyMiniSwitch.ison
# Switch off
$ShellyMiniSwitch = ((Invoke-WebRequest -Uri "http://$ShellyMini/relay/0?turn=off" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
$ShellyMiniSwitch.ison

