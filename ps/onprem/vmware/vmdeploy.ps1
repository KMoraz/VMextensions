# Allow parameters to be pushed to vmdeploy script to accept a VMname and Resourcepool:
# i.e. New-VMDeploy.ps1 -vmname CFSBCKITITST01 -resourcepool Low
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$vmname,
	
   [Parameter(Mandatory=$True)]
   [string]$resourcepool
)

# We use write-verbose to turn on-and off comment-type data for this script, backing up original preferences. 
# All comments after this point are in write-verbose format
$oldverbose = $VerbosePreference
# $VerbosePreference = "continue"

Write-Verbose "Loading PSSnapin"
Add-PSSnapin VMware.VimAutomation.Core

Write-Verbose "Connecting to vSphere Server"
Connect-VIServer -Server cfsbckvcenter01

Write-Verbose "Prompting user for "
$key = read-host -prompt "Input Datastore Keyword"

Write-Verbose "Getting a list of datastores and excludes based on matches of keyword"
$datastores = get-datastore | where {$_.Name -like "*$key*"} | select Name,FreeSpaceMB
 
Write-Verbose "Setting and clearing variables"
$LargestFreeSpace = "0"
$LargestDatastore = $null
 
Write-Verbose "Performs the calculation of which datastore has most free space"
foreach ($datastore in $datastores) {
    if ($Datastore.FreeSpaceMB -gt $LargestFreeSpace) { 
            $LargestFreeSpace = $Datastore.FreeSpaceMB
            $LargestDatastore = $Datastore.name
            }
        }
$datastore = New-Object psobject -Property @{Name = $largestdatastore
                                FreespaceMB = $largestfreespace}


# TEMPLATE CONFIGURATION

$template = "64bit 2012 Datacenter Edition"
$oscustomizationspec = "win2012 DataCenter SK"
$cluster = get-datacenter "beckenham" | get-cluster -name "AMD Cluster (Beckenham)" 

# New-VM -Name $vmname -Template $template -Datastore platinum -ResourcePool GoldCluster01 -Location CorpHQ -OSCustomizationSpec “Windows 2012 R2 – CorpHQ” Start-VM corphqdb03
# New-VM -Name $vmname -DiskStorageFormat $DiskStorageFormat -Template $vmtemplate -ResourcePool $resourcePool -VMHost (((get-cluster $cluster) | get-vmhost)[0]).Name

# BUILD DATA PUSH 

write-warning "---- Building $vmname with the following spec---"
write-warning "TEMPLATE:     $template"
write-warning "CUSTOM SPEC:  $oscustomizationspec"
write-warning "HOST:         $(((get-cluster $cluster) | get-vmhost)[0]) in $cluster"
write-warning "RESOURCEPOOL: $resourcepool"
write-warning "DATASTORE:    $($datastore.name)"

# SET ANNOTATIONS

# set-annotation -entity $vmname -customattribute "Business Unit" -value "Fund Solutions"
# set-annotation -entity $vmname -customattribute "Environment" -value "UAT"
# set-annotation -entity $vmname -customattribute "Location" -value "Beckenham"                                         
# set-annotation -entity $vmname -customattribute "SRM Protected" -value $null
# set-annotation -entity $vmname -customattribute "Server Type" -value "Application"
# set-annotation -entity $vmname -customattribute "Service" -value "Calastone"
# set-annotation -entity $vmname -customattribute "Service Owner (Business)" -value "Andy Wollaston"
# set-annotation -entity $vmname -customattribute "Service Owner (IT)" -value $null               
pause

write-verbose "Returning to original verbosity settings"
$VerbosePreference = $oldverbose
