# Powershell and Shelly Smart Home
There is no documentation and no examples how to use Shelly products with Powershell, so lets make some. Powershell is very well equipped to control the Shelly products with its built-in capabilities.

## Basic Information
All examples and are based on Powershell 5.1 which is available for Windows 7 and Server 2008 R2 up to the newest Insider builds for Windows and Windows Servers.

I recommend using my examples in Powershell-ISE, which is available in all Windows current versions, set the cursor on the line you want to try and hit the green "run selection" button.

![image](https://github.com/Joachim-Otahal/Powershell-and-Shelly-Smart-Home/assets/10100281/a3911ca5-8141-45de-9a1a-e3636fab3cc7)

Depending on the age or generation of the shelly you can use rpc commands, which are better organized, or the older query style. Sometimes there are small but useful differences between those for the same function.

The commands with examples for curl are listed at https://shelly-api-docs.shelly.cloud , and they can all be translated to powershell.

## Shelly Powershell System.Net.Http.HttpClient.ps1 ##
This real-world example uses System.Net.Http.HttpClient async with GetStringAsync in Powershell to query eight shellies in parallel for their status instead of linear Invoke-Webrequests. So on my WLAN instead of about 2 seconds or a lot more if one or more Shelly temporaty does not respond this usually needs less than a half second, at worst 700 ms.

## Shelly-Important-RPC-commands.ps1
Things like "How do I get a list of all available commands?"

## Shelly-3-EM-Pro.ps1
How do I read the power usage, and the history data for a specific time frame? (And why is the Energy usage not logged in the .CSV?)

## Shelly-1-Mini-Gen-3.ps1
Get the status, use the switch.

## Shelly-Plug-S.ps1
Get the status, use the switch.

