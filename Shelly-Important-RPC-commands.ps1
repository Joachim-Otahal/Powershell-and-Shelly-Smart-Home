# These are useful starter commands. Have fun trying them!
# I recommend using it in Powershell-ISE, which is available on all Windows installations.
# Joachim Otahal 2024-05


# Where is the device ?
$Shelly3EMIP = "192.168.33.159"


# Simple first test, will show the time zones, albeit as raw HTTP information
Invoke-WebRequest -Uri "http://$Shelly3EMIP/rpc/Shelly.ListTimezones" -Method Get -UseBasicParsing -TimeoutSec 5


# List all available rcp commands for this device
(((Invoke-WebRequest -Uri "http://$Shelly3EMIP/rpc/Shelly.ListMethods" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json).methods


# Get the status and convert the JSON into a usable object.
$Shelly3EMGetStatus = ((Invoke-WebRequest -Uri "http://192.168.33.159/rpc/Shelly.GetStatus" -Method Get -UseBasicParsing -TimeoutSec 5).RawContent -split "`n")[-1] | ConvertFrom-Json
# Temperature in celsius
$Shelly3EMGetStatus.'temperature:0'.tC
# Actual total power over all three phases. This is what the energy meter from your electricity supplier sees and you pay for.
# This is the most important information if you want to switch on devices if you have a lot of free solar power, i.e. if this readin is negative.
$Shelly3EMGetStatus.'em:0'.total_act_power
# The apparent power includes everything, even energy which is not actually metered like blind power.
$Shelly3EMGetStatus.'em:0'.total_aprt_power

# List all available data of that object recursivly. I spare you the output for obvious reasons.
# In this case you will have to mark the following 25 lines and then hit the "Papersheet-Play" button in Powershell-ISE
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
        if ($Property.TypeNameOfValue.Split(".")[-1] -ne "PSCustomObject") {
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
Get-PropertiesRecursive $Shelly3EMGetStatus -ParentName '$Shelly3EMGetStatus'

