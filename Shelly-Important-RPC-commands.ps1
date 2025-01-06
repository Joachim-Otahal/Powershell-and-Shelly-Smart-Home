# These are useful starter commands. Have fun trying them!
# I recommend using it in Powershell-ISE, which is available on all Windows installations.
# Joachim Otahal 2024-05


# Where is the device ?
$Shelly3EMIP = "192.168.33.159"

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


# Simple first test, will show the time zones, albeit as raw HTTP information
Invoke-WebRequest -Uri "http://$Shelly3EMIP/rpc/Shelly.ListTimezones" -Method Get -UseBasicParsing -TimeoutSec 5


# List all available rpc commands for this device
((Invoke-WebRequest -Uri "http://$Shelly3EMIP/rpc/Shelly.ListMethods" -Method Get -UseBasicParsing -TimeoutSec 5).Content | ConvertFrom-Json).methods


# Get the status and convert the JSON into a usable object.
$Shelly3EMGetStatus = (Invoke-WebRequest -Uri "http://192.168.33.50/rpc/Shelly.GetStatus" -Method Get -UseBasicParsing -TimeoutSec 5).Content | ConvertFrom-Json
# Temperature in celsius
$Shelly3EMGetStatus.'temperature:0'.tC
# Actual total power over all three phases. This is what the energy meter from your electricity supplier sees and you pay for.
# This is the most important information if you want to switch on devices if you have a lot of free solar power, i.e. if this readin is negative.
$Shelly3EMGetStatus.'em:0'.total_act_power
# The apparent power includes everything, even energy which is not actually metered like blind power.
$Shelly3EMGetStatus.'em:0'.total_aprt_power

# List all status information in a readable way.
Get-PropertiesRecursive $Shelly3EMGetStatus -ParentName '$Shelly3EMGetStatus'
