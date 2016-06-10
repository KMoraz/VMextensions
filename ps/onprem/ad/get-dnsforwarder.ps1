# Define a domain to investigate
$domain = "adcfs.capita.co.uk"

# Use built-in functionality to get the current forest
$myForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

# Get a list of Sites
# For each Site, get the list of dcs, from the list take only the name
$dc_list = $myforest.Sites | % { $_.Servers } | Select Name

# Create the data array. R N are just escape characters for new lines
$result="Controller	Forwarders `r`n"

# For each DC, get the info and add to the data array
foreach ($dc in $dc_list) {
    $DCName = $dc.Name
    $Server = Get-WmiObject -Computer $DCName -Namespace "root\MicrosoftDNS" -Class "MicrosoftDNS_Server"
    $Forwarders = $Server.Forwarders
    $result+=$DCName+":"+$Forwarders+"`r`n"
}

# Output the data array to a file
$result|Out-File c:\temp\dnsresult.txt