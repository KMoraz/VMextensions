function Show-Menu
{
     param (
           [string]$Title = 'My Menu'
     )
     cls
     Write-Host "================ $Title ================"
     
     Write-Host "1: Press '1' for this option."
     Write-Host "2: Press '2' for this option."
     Write-Host "3: Press '3' for this option."
     Write-Host "Q: Press 'Q' to quit."
}



# How do I get a list of the Vmware tools on each virtual machine?
get-vm | % { get-view $_.id } | select Name, @{ Name="ToolsVersion"; Expression={$_.config.tools.toolsVersion}},@{ Name="ToolStatus"; Expression={$_.Guest.ToolsVersionStatus}}

# How do I get a list of the Vmware tools on each powered on virtual machine?
get-datacenter 'beckenham' | get-vm | where {$_.powerstate -ne "PoweredOff" } | % { get-view $_.id } | select Name, @{ Name="ToolsVersion"; Expression={$_.config.tools.toolsVersion}},@{ Name="ToolStatus"; Expression={$_.Guest.ToolsVersionStatus}}

# How do I get a list of the Vmware tools that are not up to date on each powered on virtual machine?
get-datacenter 'beckenham' |  get-vm | where {$_.powerstate -ne "PoweredOff" } | where {$_.Guest.ToolsVersionStatus -ne "guestToolsCurrent"} | % { get-view $_.id } | select Name, @{ Name="ToolsVersion"; Expression={$_.config.tools.toolsVersion}}, @{ Name="ToolStatus"; Expression={$_.Guest.ToolsVersionStatus}}

# How do I get a list of the Vmware tools that are not up to date on each powered on virtual machine and output it to csv?
get-vm | where {$_.powerstate -ne "PoweredOff" } | where {$_.Guest.ToolsVersionStatus -ne "guestToolsCurrent"} | % { get-view $_.id } | select Name, @{ Name="ToolsVersion"; Expression={$_.config.tools.toolsVersion}}, @{ Name="ToolStatus"; Expression={$_.Guest.ToolsVersionStatus}} | Export-Csv -NoTypeInformation -UseCulture -Path C:\Temp\VMHWandToolsInfo.csv