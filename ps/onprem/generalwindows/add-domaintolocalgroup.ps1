#Get List of Servers from Flat TXT file 
$Servers = @()

$servers += "cfsbckitirds01"
$servers += "cfsbckitirds02"
$servers += "cfsbckitirds03"
$servers += "cfsbckitirds04"

#Initialize the Domain Group Object 
$DomainGroup = [ADSI]"WinNT://adcfs/Farm_RDS_CFSBCKRDSFarm_All,group" 
 
 
ForEach ($Server in $Servers) #Loop through each server 
{ 
    #Get Local Group object 
    $LocalGroup = [ADSI]"WinNT://$Server/Remote Desktop Users,group" 
 
    #Assign DomainGroup to LocalGroup 
    $LocalGroup.Add($DomainGroup.Path) 
 
    #Determine if command was successful 
    } 