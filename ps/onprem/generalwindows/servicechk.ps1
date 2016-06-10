$Result = @()

#$Servers = Get-ADComputer -filter {operatingsystem -like "*Server*"} `
$Servers = Get-Content ("c:\scripts\temp\servers.txt")
#$Servers = Read-Host "Enter server name"
$outfile = ($SCRIPT_PARENT + "\ServiceAccounts_{0:yyyyMMdd-HHmm}.csv"-f (Get-Date))

Foreach ($Server in $servers) {

$i++
   Write-Progress -activity "Running....." -status "Count: $i of $($Servers.count)" -percentComplete (($i / $Servers.count) * 100)

$pingStatus = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$Server'"
#$Ping =    Test-Connection -Quiet -ComputerName $server -Count 1

if($pingStatus.StatusCode -eq 0) {

$Resolve = [System.Net.Dns]::Resolve($server)
$FQDN = $Resolve.HostName

write-Host "Getting Service details from - ($Server)" -ForegroundColor Magenta

#$StandardServiceAccounts = "LocalSystem", "NT AUTHORITY\LocalService", "NT AUTHORITY\NetworkService"

$SrvcS = Get-WmiObject win32_service -ComputerName $Server 

}
Foreach($Srvc in $SrvcS ) {

If(($Srvc.StartName -ne "LocalSystem") -and ($Srvc.StartName -ne "NT AUTHORITY\LocalService") -and ($Srvc.StartName -ne "NT AUTHORITY\NetworkService") )
   {
   $Result += New-Object PSObject -Property @{
        ServerName = $Server
        FQDN = $FQDN
        Status = $GetStatusCode = ($pingStatus.StatusCode)
        Name = $Srvc.Name
        StartName = $Srvc.StartName
        StartMode = $Srvc.StartMode
    }
                          }
else {
#-----------------------
$Resolve = " "
#$Resolve = [System.Net.Dns]::Resolve($server)
#if ($Resolve -ne ""){
$FQDN = $Resolve.HostName
    #    }
#-----------------------
write-Host "Server is not accessible - ($Server)" -ForegroundColor Red

$Result += New-Object PSObject -Property @{
        ServerName = $Server
        FQDN = $FQDN
        Status = GetStatusCode( $pingStatus.StatusCode )
        Name = "NA"
        StartName = "NA"
        StartMode = "NA"
}
}
$Result | select ServerName, FQDN, Status, Name, StartName, StartMode | Export-csv -NoTypeInformation -Path $OutFile -UseCulture


}