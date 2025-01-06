# These are more complex examples for Shelly 3 EM Pro. Yes, some of it is from the Shelly-Important-RPC-commands.ps1
# I recommend using it in Powershell-ISE, which is available on all Windows installations.
# Joachim Otahal 2024-05


# Where is the device ?
$Shelly3EMIP = "192.168.33.50"

function Get-PropertiesRecursive {
    param (
        [Parameter(ValueFromPipeline)][object]$InputObject,
        [String]$ParentName,
        [int]$MaxDepth = 10
    )
    if ($ParentName) {$ParentNameDot ="$ParentName."} else {$ParentNameDot = ""}
    foreach ($Property in $InputObject.psobject.Properties) {
        # This puts special characters in '' like you need it when using it directly with powershell
        if ($Property.Name -like "*:*" -or $Property.Name -like "* *"  -or $Property.Name -like "*-*") {
            $Name = "'$($Property.Name)'"
        } else {
            $Name = $Property.Name
        }
        $PropertyTypeName = $Property.TypeNameOfValue.Split('.')[-1]
        if (($PropertyTypeName -ne "PSCustomObject" -and $PropertyTypeName -notlike "Object*") -or
            # Catch simple recursion
            $ParentName.Split('.')[-1] -eq $Name -or $MaxDepth -le 0) {
            [pscustomobject]@{
                TypeName = $PropertyTypeName
                Property = "$ParentNameDot$Name"
                Value = $Property.Value
            }
        } else {
            Get-PropertiesRecursive $Property.Value -ParentName "$ParentNameDot$Name" -MaxDepth $($MaxDepth-1)
        }
    }
}


# List all available rpc commands for this device
((Invoke-WebRequest -Uri "http://$Shelly3EMIP/rpc/Shelly.ListMethods" -Method Get -UseBasicParsing -TimeoutSec 5).Content | ConvertFrom-Json).methods


# Get the status and convert the JSON into a usable object.
$Shelly3EMGetStatus = (Invoke-WebRequest -Uri "http://$Shelly3EMIP/rpc/Shelly.GetStatus" -Method Get -UseBasicParsing -TimeoutSec 5).Content | ConvertFrom-Json
# Temperature in celsius
$Shelly3EMGetStatus.'temperature:0'.tC
# Actual total power over all three phases. This is what the energy meter from your electricity supplier sees and you pay for.
# This is the most important information if you want to switch on devices if you have a lot of free solar power, i.e. if this readin is negative.
$Shelly3EMGetStatus.'em:0'.total_act_power
# The apparent power includes everything, even energy which is not actually metered like blind power.
$Shelly3EMGetStatus.'em:0'.total_aprt_power

# List all status information in a readable way.
Get-PropertiesRecursive $Shelly3EMGetStatus -ParentName '$Shelly3EMGetStatus'


# Get the configuration
$Shelly3EMGetConfig = (Invoke-WebRequest -Uri "http://$Shelly3EMIP/rpc/Shelly.GetConfig" -Method Get -UseBasicParsing -TimeoutSec 5).Content | ConvertFrom-Json

# List all config information in a readable way.
Get-PropertiesRecursive $Shelly3EMGetConfig -ParentName '$Shelly3EMGetConfig'


# Power log of the last 90 days
# Question to Shelly: Why does it not include a "WattMinute" or "WattHour" for each minute? And why does it not include "total_act_power" or "total_avg_power"?
# WARNING: This take a long time!
$Shelly3EMDat = (Invoke-WebRequest -Uri "http://$Shelly3EMIP/emdata/0/data.csv?add_keys=true" -Method Get -UseBasicParsing -TimeoutSec 5).content | ConvertFrom-Csv | Select-Object DateTime,power_avg,power_min,power_max,*
# Since ".total_act_power" or ".total_avg_power" is missing in the log we cheat-calculate it...
# And while we are there we format the date in ISO8601 format, local time, so every spreadsheet program can handle it.
# See https://xkcd.com/1179/
for ($i = 0 ; $i -lt $Shelly3EMDat.Count;$i++) {
    $Shelly3EMDat[$i].DateTime = (Get-Date "1970-01-01Z").ToUniversalTime().AddSeconds($Shelly3EMDat[$i].timestamp).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss")
    # Cheat calculate the .avg_power
    $Shelly3EMDat[$i].power_min = [Math]::Round(
            $Shelly3EMDat[$i].a_min_act_power.ToDecimal([System.Globalization.CultureInfo]::InvariantCulture) +
            $Shelly3EMDat[$i].b_min_act_power.ToDecimal([System.Globalization.CultureInfo]::InvariantCulture) +
            $Shelly3EMDat[$i].c_min_act_power.ToDecimal([System.Globalization.CultureInfo]::InvariantCulture)
        )
    $Shelly3EMDat[$i].power_max = [Math]::Round(
            $Shelly3EMDat[$i].a_max_act_power.ToDecimal([System.Globalization.CultureInfo]::InvariantCulture) +
            $Shelly3EMDat[$i].b_max_act_power.ToDecimal([System.Globalization.CultureInfo]::InvariantCulture) +
            $Shelly3EMDat[$i].c_max_act_power.ToDecimal([System.Globalization.CultureInfo]::InvariantCulture)
        )
    $Shelly3EMDat[$i].power_avg = ($Shelly3EMDat[$i].power_min + $Shelly3EMDat[$i].power_max)/2
}
# Export file
$FileName = "$env:USERPROFILE\Desktop\Shelly3EMData $(Get-Date -Format "yyyy-MM-dd HH_mm_ss").csv"
# For Germany and any other country where the default delimiter in Excel is ";": Uncomment this.
# $Shelly3EMDat | Export-Csv -Delimiter ";" -Path $FileName -NoTypeInformation -Encoding UTF8
# For everyone else which uses "," as delimiter
$Shelly3EMDat | Export-Csv -Path $FileName -NoTypeInformation -Encoding UTF8


# Power log of the last three days:
$UnixTimeFrom = [uint64]((Get-Date).AddDays(-3).ToUniversalTime()-(Get-Date "1970-01-01Z").ToUniversalTime()).TotalSeconds
#$UnixTimeTo   = [uint64]((Get-Date)-(Get-Date "1970-01-01Z").ToUniversalTime()).TotalSeconds
$Shelly3EMDat = (Invoke-WebRequest -Uri "http://$Shelly3EMIP/emdata/0/data.csv?add_keys=true&ts=$UnixTimeFrom" -Method Get -UseBasicParsing -TimeoutSec 5).content | ConvertFrom-Csv| Select-Object DateTime,power_avg,power_min,power_max,*
# Now rerun that for loop from above


# Power log for a specific date frame (currently buggy):
$UnixTimeFrom = [uint64]((Get-Date "2024-05-11 00:00:00").ToUniversalTime()-(Get-Date "1970-01-01Z").ToUniversalTime()).TotalSeconds
$UnixTimeTo   = [uint64]((Get-Date "2024-05-12 23:59:59").ToUniversalTime()-(Get-Date "1970-01-01Z").ToUniversalTime()).TotalSeconds
$Shelly3EMDat = (Invoke-WebRequest -Uri "http://$Shelly3EMIP/emdata/0/data.csv?add_keys=true&ts=$UnixTimeFrom&end_ts=$UnixTimeTo" -Method Get -UseBasicParsing -TimeoutSec 5).content | ConvertFrom-Csv| Select-Object DateTime,power_avg,power_min,power_max,*
# Now rerun that for loop from above


# Power log for a specific hour:
$UnixTimeFrom = [uint64]((Get-Date "2024-05-11 11:00:00").ToUniversalTime()-(Get-Date "1970-01-01Z").ToUniversalTime()).TotalSeconds
$UnixTimeTo   = [uint64]($UnixTimeFrom+3599)
$Shelly3EMDat = (Invoke-WebRequest -Uri "http://$Shelly3EMIP/emdata/0/data.csv?add_keys=true&ts=$UnixTimeFrom&end_ts=$UnixTimeTo" -Method Get -UseBasicParsing -TimeoutSec 5).content | ConvertFrom-Csv| Select-Object DateTime,power_avg,power_min,power_max,*
# Now rerun that for loop from above
