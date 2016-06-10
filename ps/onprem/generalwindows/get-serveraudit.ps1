
# Set expiry
$expiry = (Get-date).AddDays(-90)
# clear stalecandidate file
$stalecandidates = out-null
# generate stalecandidate file
$stalecandidates = (Get-ADComputer -Filter {OperatingSystem -Like "*Server*"} -Property * |`
 select Name,Description,IPv4Address,OperatingSystem,OperatingSystemServicePack,Operatingsystemversion,Passwordlastset,lastlogontimestamp)


# Set outfile
$outfile = "c:\Scripts\Servers_$((Get-Date).ToString('dd-MM-yyyy')).csv" `
# Test path for outfile, create it if absent
if(!(Test-Path -Path $outfile))
 {
  new-item -Path $outfile –itemtype file -force
 }
 
# Loop  for each server in stalecandidates
$collection = $()
foreach ($stalecandidate in $stalecandidates)
{
    $status = @{ "ServerName" = $stalecandidate.name;
     
     "Description"= $stalecandidate.Description;
     "IPv4"= $stalecandidate.IPv4Address;
     "OS"= $stalecandidate.OperatingSystem;
     "SP"= $stalecandidate.OperatingSystemServicePack;
     "OS Version"= $stalecandidate.Operatingsystemversion;
     "Last Password Set"= $stalecandidate.Passwordlastset;
     "Last Logon Timestamp" = ([DateTime]::FromFileTime($stalecandidate.LastLogontimestamp))
         
     }
    if (Test-Connection $stalecandidate.name -Count 1 -ea 0 -Quiet)
    { 
        $status["Ping"] = "Up"
    } 
    else 
    { 
        $status["Ping"] = "Down" 
    }
    New-Object -TypeName PSObject -Property $status -OutVariable serverStatus
    $collection += $serverStatus

}
$collection | Export-Csv $outfile -NoTypeInformation
invoke-item $outfile
