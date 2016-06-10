
Function Start-containerwithNAT ($containername)
        {

start-container $containername
$ContainerIP = get-containerip $containername


$natportmp = $null
$NATPortTmp = Show-NetFirewallRule | Where InstanceID -eq "Container NAT $ContainerName" | ForEach-Object {$_.LocalPort}

$natport = $null
$NATPort = [uint16]($natporttmp | out-string)
$ContainerPort = Get-NetNatStaticMapping | Where ExternalPort -eq $NATPort | ForEach-Object {$_.InternalPort}
Get-NetNatStaticMapping | Where ExternalPort -eq $NATPort | Remove-NetNatStaticMapping -Confirm:$false
Add-NetNatStaticMapping -NatName "NAT" -Protocol TCP -ExternalPort $NATPort -ExternalIPAddress 0.0.0.0 -InternalPort $ContainerPort -InternalIPAddress $($ContainerIP.ip)

Write-Host "Container $ContainerName has started with IP $($ContainerIP.ip)" -ForegroundColor Yellow

}