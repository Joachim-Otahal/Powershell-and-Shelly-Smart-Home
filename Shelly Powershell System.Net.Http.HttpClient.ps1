# Powershell using System.Net.Http.HttpClient Async in masses parallel. 
# Compared to Invoke-Webrequest this allows querying all my Shellies in parallel instead of one after the other.
# Thus allows a control-reaction loop of less than three seconds.
# Growatt MIC and Marsteck Venus E are queried and controlled serial via RS485 and are not included here.
#
# This is the real-world example of mass-query 8 shelly statuses via WLAN in, usually, less than a half second.
# Yes, my writing style is not based on "You are paid by the number of lines you code!"
#
# September 2025 Joachim Otahal

# Shelly 3 EM Pro. There are not my real IPs, obviously.
$Shelly3EMIP="192.168.777.350"
# Plugs.
$SPlugBalkIP="192.168.777.640"   # Balcony HM 600
$SPlugWohnIP="192.168.777.641"   # Living room HM 300
$SPlugKuchIP="192.168.777.642"   # Kitchen HM 300
$SPlugFanIP="192.168.777.643"    # Control external cooling fans for Growatt MIC + Marstek Venus E.
# Boiler
$SBoilSw1IP = "192.168.777.355"  # Shelly Plus 1PM -> Main Boiler On-Off including measure actual PSU usage.
$SBoilSw2IP = "192.168.777.352"  # Shelly 1 Mini Gen 3 -> Control "StandBy" switch of CHUX 2000W regulatable PSU, making the start/stop softer for the Shelly Plus 1PM.
$SBoilDi1IP = "192.168.777.357"  # Shelly Plus 0-10V light-grey dimmer, used as sinking dimmer for CHUX 2000W PSU-Current-adjustment.
# More will come, but not this month.

# Since some have different calls we array the http requests ahead.
$Urls=@{}
$Urls["Shelly3EM"]="http://$Shelly3EMIP/rpc/Shelly.GetStatus"
$Urls["SPlugBalk"]="http://$SPlugBalkIP/rpc/Shelly.GetStatus"
$Urls["SPlugWohn"]="http://$SPlugWohnIP/rpc/Shelly.GetStatus"
$Urls["SPlugKuch"]="http://$SPlugKuchIP/rpc/Shelly.GetStatus"
$Urls["SBoilSw1"]="http://$SBoilSw1IP/rpc/Shelly.GetStatus"
$Urls["SBoilSw2"]="http://$SBoilSw2IP/rpc/Shelly.GetStatus"
$Urls["SBoilDi1"]="http://$SBoilDi1IP/rpc/Light.GetStatus?id=0"
$UrlsKeys=$Urls.Keys.Split("`n")
Add-Type -AssemblyName System.Net.Http
$HC = [System.Net.Http.HttpClient]::new()
$HC.Timeout=[timespan]::new(0,0,0,0,600) # Tested as combination of response-speed and WLAN pickyness. 400 works, 600 to leave room when WLAN is busy.
$HCResult=@{}
$HCObject=@{}
# Here would be a control loop start to check every three seconds.
$HCGet=@{}
for ($iUrl=0;$iUrl -lt $Urls.Count;$iUrl++) {
    if ($HCResult[$UrlsKeys[$iUrl]] -eq $null) { # Init result array only on first run
        $HCResult[$UrlsKeys[$iUrl]]=$false
    }
    $HCGet[$UrlsKeys[$iUrl]] = $HC.GetStringAsync($Urls[$UrlsKeys[$iUrl]])
}
Start-Sleep -Milliseconds 100
for ($iUrl=0;$iUrl -lt $Urls.Count;$iUrl++) {
    try {
        $HCtmp = $HCGet[$UrlsKeys[$iUrl]].GetAwaiter().GetResult()
    } catch {
        $Error.RemoveAt(0) # We remove last error which we don't want the errorlog.
        $HCtmp=""
        Write-Verbose "FAILED Index $iUrl, key $($UrlsKeys[$iUrl]), Url $($Urls[$UrlsKeys[$iUrl]])" -Verbose
    }
    if ($HCRestmp.Length -gt 50) {
        $HCResult[$UrlsKeys[$iUrl]]=$HCtmp
        $HCObject[$UrlsKeys[$iUrl]]=$HCtmp | ConvertFrom-Json
    } # else { # This is only for testing how tight the timeouts and loop can be. If there is no response the previous reading will be cleared with $false.
      #   $HCResult[$UrlsKeys[$iUrl]]=$false
      #   $HCResultobject[$UrlsKeys[$iUrl]]=$null
      # }
}
$HCResult
$HCResultobject
# Here would be the "do this and that according to the values" of the control loop.
# Here would be the exit condition of the control loop.
$HC.Dispose()
