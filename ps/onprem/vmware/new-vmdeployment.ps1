 [CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$CSV
	
)

$VerbosePreference = 'silentlycontinue';
$global:VerbosePreference = 'silentlyContinue';

clear-host


# _____________________ #
#                       #
# ___ CSV IMPORT 1/2 __ #
# _____________________ #


#. write-verbose "Setting ErrorAction Preference to STOP for CSV check"
$ErrorActionPreference = "stop"
#. write-verbose "Creating requested build array and filling it with imported CSV data"
remove-variable '$requestedbuild' -erroraction SilentlyContinue
$requestedbuild = @()
$requestedbuild = import-csv $csv
# Remove original CSV
remove-item $csv -ErrorAction SilentlyContinue


# _____________________ #
#                       #
# _ MAP REMOTE SHARE __ #
# _____________________ #
#
# This will map a temporary PSDrive to send and recieve scripts and logs

$localpsdrive = "\\CFSBCKITINFS01\software$\new-vmdeployment"
if ((test-path $localpsdrive -pathtype Container) -eq $false)
    {New-PSDrive –Name LocalPSDrive –PSProvider FileSystem –Root $localpsdrive}


# _____________________ #
#                       #
# ___ LOG FUNCTION ____ #
# _____________________ #
#
# This is our logging function, it must appear above the code where you are trying to use it.

# Define a new log name
$logfile = $localpsdrive + "\logs\" + $(get-date -uformat %d%m%y) + "_" + $requestedbuild.ServerName + ".log"

# Remove an existing log for the same server/date if it exists
remove-item $logfile -ErrorAction SilentlyContinue

function log($string, $color)
{
   if ($Color -eq $null) {$color = "white"}
   write-host $string -foregroundcolor $color
   $string | out-file -Filepath $logfile -append
}


# _____________________ #
#                       #
# ___ CSV IMPORT 1/2 __ #
# _____________________ #
#
# Just used to log the import a few steps earlier


log "Ingesting VM CSV data as below" white
log $requestedbuild white


# _____________________ #
#                       #
# _ GUEST IP FUNCTION _ #
# _____________________ #

Function Set-WinVMIP ($VM, $GC, $IP, $SNM, $GW){
 $netsh = "c:\windows\system32\netsh.exe interface ip set address ""Ethernet"" static $IP $SNM $GW 1"
 log "$(get-date) - Setting IP info for $VM"
 
 log "       Setting IP address for $VM to $IP..." darkgreen
 Invoke-VMScript -VM $VM -GuestCredential $GC -ScriptType bat -ScriptText $netsh
 log "       ...completed." darkgreen
}

# _____________________ #
#                       #
# _ GUEST DNS FUNCTION_ #
# _____________________ #

Function Set-WinVMDNS ($VM, $GC, $DNS1, $DNS2){
 $netsh = "c:\windows\system32\netsh.exe interface ipv4 delete dnsserver name=""Ethernet"" addr=all"
 log "$(get-date) - Setting DNS info for $VM"
 
 log "       Clearing any existing DNS for $VM..." darkgreen
 Invoke-VMScript -VM $VM -GuestCredential $GC -ScriptType bat -ScriptText $netsh
 $netsh = "c:\windows\system32\netsh.exe interface ipv4 add dnsserver ""Ethernet"" $DNS1 validate=no index=1"
 
 log "       Setting Primary DNS address to $DNS1 for $VM..." darkgreen
 Invoke-VMScript -VM $VM -GuestCredential $GC -ScriptType bat -ScriptText $netsh
 log "       ...completed." darkgreen
 
 $netsh = "c:\windows\system32\netsh.exe interface ipv4 add dnsserver ""Ethernet"" $DNS2 validate=no index=2"
 log "       Setting Secondary DNS address to $DNS2 for $VM..." darkgreen
 Invoke-VMScript -VM $VM -GuestCredential $GC -ScriptType bat -ScriptText $netsh
 
 log "       ...completed." darkgreen
}

# _____________________ #
#                       #
# __ CREDENTIAL MGR ___ #
# _____________________ #

$secpasswd = ConvertTo-SecureString "W0rmhole" -AsPlainText -Force
$GuestCred = New-Object System.Management.Automation.PSCredential ("Administrator", $secpasswd)

# _____________________ #
#                       #
# __ ADMIN FUNCTION ___ #
# _____________________ #

log "$(get-date) - Script run by $(get-content env:username)" gray
log "$(get-date) - Script run on $(get-content env:computername)" gray

# _____________________ #
#                       #
# __ CONNECT VSPHERE __ #
# _____________________ #


#. write-verbose "Loading PSSnapin"
if ( (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PsSnapin VMware.VimAutomation.Core
}

Set-powercliconfiguration -InvalidCertificateAction ignore -scope session -confirm:$false

Connect-VIServer -Server cfsbckvcenter01 -force 

# _____________________ #
#                       #
# __ EXISTING VM CHK __ #
# _____________________ #

# Checking if VM exists by name

if(!((get-vm $requestedbuild.servername -ErrorAction silentlycontinue).Name -eq $null))
            {
            clear-host
            log "$(get-date) - $($requestedbuild.servername) exists in VMware, similar servers:" red
            $namecheck = ($($requestedbuild.servername).substring(0,12)).trim()
            $namecheck = $namecheck + "*"
            $vmlist = get-vm -name $namecheck
            $vmlist | %{log "       $($_.Name)" red}
            $requestedbuild.servername = read-host "VM with this name already exists, please enter new name:"
            log "$($requestedbuild.servername) chosen as new name, checking..."
            
            # Rename the old logfile with the new name
            $newlogfile = $localpsdrive + "\logs\" + $(get-date -uformat %d%m%y) + "_" + $requestedbuild.ServerName + ".log"
            remove-item $newlogfile -erroraction SilentlyContinue
            rename-item $logfile $newlogfile -erroraction SilentlyContinue
            $logfile = $newlogfile
            }

# Bailing out if neccesary

if(!((get-vm $requestedbuild.servername -ErrorAction silentlycontinue).Name -eq $null))
            {
            log "$(get-date) - New VM name has been taken too, please run UPDATE in server Form" red
            log "       Bailing process out now..." red
            exit
            }

# _____________________ #
#                       #
# ___ DATASTORE CHK ___ #
# _____________________ #
#
#
# Original keyword check:
#
# #. write-verbose "Getting a list of datastores and excludes based on matches of keyword AND storage profile location"
#    $datastores = get-datastore | where {($_.Name -like "*$($requestedbuild.storagekeyword)*") -and ($_.Name -like "*$($requestedbuild.storagelocation)*")} | select Name,FreeSpaceMB
# #. write-verbose "Catching a list of datastores and excludes based on matches of keyword ONLY"
# if (!$datastores) {$datastores = get-datastore | where {$_.Name -like "*$($requestedbuild.storagekeyword)*"} | select Name,FreeSpaceMB}
# if (!$datastores) {$manualdatastorename = read-host "Autodetect failed for keyword ""$($requestedbuild.storagekeyword)"", please enter valid datastore" ;
#                     $datastores = get-datastore $manualdatastorename}
#
#
# Original space calc check:
#  
#        #. write-verbose "Setting and clearing variables"
#            $LargestFreeSpace = "0"
#            $LargestDatastore = $null
# 
#           #. write-verbose "Performs the calculation of which datastore has most free space"
#               foreach ($datastore in $datastores)
#                   {
#                   if ($Datastore.FreeSpaceMB -gt $LargestFreeSpace) 
#                           { 
#                           $LargestFreeSpace = $Datastore.FreeSpaceMB
#                           $LargestDatastore = $Datastore.name
#                           }
#                   }
#
# #. write-verbose "Creating a new PSObject with Datastore Info"
#    $datastore = New-Object psobject -Property @{Name = $largestdatastore
#                                                FreespaceMB = $largestfreespace}
                                               

# _____________________ #
#                       #
# __ TEMPLATE BUILD ___ #
# _____________________ #


####################################################
### Quick and Dirty Catch and Static Definitions ### 
####################################################     

# Datastore 
     $largestdatastore = get-datastore "3PAR T400 ESXi IT Test Script"
        log "$(get-date) - Chosen datastore $($largestdatastore)" cyan

# VM Host Cluster
     $cluster = get-datacenter "beckenham" | get-cluster -name "AMD Cluster (Beckenham)" 
# Resource Pool
      $resourcepool = get-cluster $cluster | get-resourcepool medium
# Folder Location
     $location = Get-Datacenter beckenham | get-folder "proof of concept systems"

log "$(get-date) - Building $($requestedbuild.servername) with the following spec:-" yellow
log "       Template:     $($requestedbuild.servertemplate)" darkyellow
log "       Custom Spec:  $($requestedbuild.servercustomspec)" darkyellow
log "       Host/Cluster: $(((get-cluster $cluster) | get-vmhost)[0]) in $cluster" darkyellow
log "       ResourcePool: $($resourcepool)" darkyellow
log "       Datastore:    $($largestdatastore.name)" darkyellow

####################################################
### Quick and Dirty Catch and Static Definitions ### 
####################################################     


# _____________________ #
#                       #
# ____ DEPLOY VM ______ #
# _____________________ #

log "$(get-date) - Deploying VM $($requestedbuild.servername)" magenta 
Start-Sleep -s 2

 New-VM   -runasync -Name $requestedbuild.servername `
            -VMHost $(((get-cluster $cluster) | get-vmhost)[0])`
            -Template $requestedbuild.servertemplate `
            -Datastore $($largestdatastore.name) `
            -ResourcePool $($resourcepool) `
            -OSCustomizationSpec $($requestedbuild.servercustomspec)`
            -Location $location;

# _____________________ #
#                       #
# ___ CATCH CUSTOM ____ #
#         SPEC          #
# _____________________ #

 if ($($requestedbuild.serverresourceallocation -eq "Custom"))
           {
            log "$(get-date) - Caught a custom machine spec for $($requestedbuild.servername) :-" yellow         
            
            $requestedbuild.serverresourceram
            
            
            # Check CPU value is valid and appropriate
            log "       CPU count   : $($requestedbuild.serverresourcecpu)" darkyellow
                            # Try 
                            try   { 
                                    [int]$requestedbuild.serverresourcecpu | out-null
                                  }
                            catch { 
                                    $requestedbuild.serverresourcecpu = 2
                                    log "       CPU count not valid, defaulting to : $($requestedbuild.serverresourcecpu)" darkyellow 
                                  }
                            if    ($([int]$requestedbuild.serverresourcecpu) -gt 8)
                                  {
                                    $requestedbuild.serverresourcecpu = 8
                                    log "       CPU count too high, defaulting to : $($requestedbuild.serverresourcecpu)" darkyellow 
                                  }
            
            # Check RAM value is valid and appropriate
            log "       Memory allocation   : $($requestedbuild.serverresourceram)" darkyellow
                            # Try 
                            try   { 
                                    [int]$requestedbuild.serverresourceram | out-null
                                  }
                            catch { 
                                    $requestedbuild.serverresourceram = 4
                                    log "       Memory allocation not valid, defaulting to : $($requestedbuild.serverresourceram)" darkyellow 
                                  }
                            if    ($([int]$requestedbuild.serverresourceram) -gt 8)
                                  {
                                    $requestedbuild.serverresourceram = 8
                                    log "       Memory allocation too high, defaulting to : $($requestedbuild.serverresourceram)" darkyellow 
                                  }

            # Check NIC value is valid and appropriate
            log "       NIC count   : $($requestedbuild.serverresourcenic)" darkyellow
                            # Try 
                            try   { 
                                    [int]$requestedbuild.serverresourcenic | out-null
                                  }
                            catch { 
                                    $requestedbuild.serverresourcenic = 1
                                    log "       NIC count not valid, defaulting to : $($requestedbuild.serverresourcenic)" darkyellow 
                                  }
                            if    ($([int]$requestedbuild.serverresourcenic) -gt 3)
                                  {
                                    $requestedbuild.serverresourcenic = 1
                                    log "       NIC count too high, defaulting to : $($requestedbuild.serverresourcenic)" darkyellow 
                                  }
            # Set Memory and CPU from Custom settings
            Set-vm $requestedbuild.servername -numcpu $($requestedbuild.serverresourcecpu) -memoryGB $($requestedbuild.serverresourceram) -confirm:$false
                           }

# _____________________ #
#                       #
# ___ CATCH EXTRA  ____ #
#         DISKS         #
# _____________________ #

 if ($($requestedbuild.additionaldiskD -ne ''))
           {
            log "$(get-date) - Caught a Custom Disk Layout" yellow
            log "       Ignoring for now" darkyellow
                       }

# _____________________ #
#                       #
# ___ WRITE NOTES  ____ #
# _____________________ #

log "$(get-date) - Writing VM notes:-" yellow
Start-Sleep -s 2
 
log "       Setting Business Unit value to $($requestedbuild.Businessunit)" darkyellow
set-annotation -entity $($requestedbuild.servername) -customattribute "Business Unit"  -value $($requestedbuild.Businessunit)

log "       Setting Environment value to $($requestedbuild.environment)" darkyellow
set-annotation -entity $($requestedbuild.servername) -customattribute "Environment"  -value $($requestedbuild.environment)

log "       Setting Location value to $($requestedbuild.location)"                  darkyellow                
set-annotation -entity $($requestedbuild.servername) -customattribute "Location"  -value $($requestedbuild.location)                            

log "       Setting SRM Protected value to $($requestedbuild.srmprotected)" darkyellow
set-annotation -entity $($requestedbuild.servername) -customattribute "SRM Protected"  -value $($requestedbuild.srmprotected)

log "       Setting Server Type value to $($requestedbuild.servertype)" darkyellow
set-annotation -entity $($requestedbuild.servername) -customattribute "Server Type"  -value $($requestedbuild.servertype)

log "       Setting Service value to $($requestedbuild.service)" darkyellow
set-annotation -entity $($requestedbuild.servername) -customattribute "Service"  -value $($requestedbuild.service)

log "       Setting Service Owner (Business) value to $($requestedbuild.serviceownerbusiness)" darkyellow
set-annotation -entity $($requestedbuild.servername) -customattribute "Service Owner (Business)"  -value $($requestedbuild.serviceownerbusiness)

log "       Setting Service Owner (IT) value to $($requestedbuild.serviceownerit)" darkyellow
set-annotation -entity $($requestedbuild.servername) -customattribute "Service Owner (IT)"  -value $($requestedbuild.serviceownerit)

# _____________________ #
#                       #
# _____ START VM ______ #
# _____________________ #

log "$(get-date) - Manually starting VM $($requestedbuild.servername)" magenta 

start-vm $($requestedbuild.servername)
        log "$(get-date) - Powered on $($requestedbuild.servername)" magenta 
        log "$(get-date) - Checking for succesful OS boot..." magenta 

            $toolsStatus = $false
            do {
                $toolsStatus = (Get-VM $requestedbuild.servername | Get-View).Guest.GuestOperationsReady
                sleep 1
               } until ( $toolsStatus -eq $true)

log "$(get-date) - ...booted successfully. Sleeping during auto-restart." magenta 
        Start-Sleep -s 240

log "$(get-date) - Checking for succesful OS reboot..." magenta
            $toolsStatus = $false
            do {
                $toolsStatus = (Get-VM $requestedbuild.servername | Get-View).Guest.GuestOperationsReady
                sleep 1
                } until ( $toolsStatus -eq $true)

log "$(get-date) - ... booted to interactive mode." magenta 

# _____________________ #
#                       #
# __ GUEST OS CONFIG __ #
# _____________________ #

log "$(get-date) - Starting VM Guest OS configuration" green 

# _____________________ 
#                       
# _ SETTING GUEST IP __ 
# _____________________ 

try     {
            Set-WinVMIP $requestedbuild.servername $GuestCred $($requestedbuild.ipaddress) $($requestedbuild.subnetmask) $($requestedbuild.defaultgateway)
        }
catch   {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            log $errormessage red
            log $faileditem red
        }

# _____________________ 
#                       
# _ SETTING GUEST DNS __ 
# _____________________ 

# Splitting DNS from single variable and trimming
    $DNS1,$DNS2 = $requestedbuild.DNS.split(',',2)
    $DNS1 = $DNS1.trim()
    $DNS2 = $DNS2.trim()

try   {
            Set-WinVMDNS $requestedbuild.servername $GuestCred $dns1 $dns2
      }
catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            log $errormessage red
            log $faileditem red
      }


#log "Mapping Network Drive for Scripting and Logging"

#$scriptpath = "CFSBCKITINFS01\software$\new-vmdeployment\Scripts"""
#$scriptlog = '&"New-PSDrive –Name ScriptDrive –PSProvider FileSystem –Root $scriptpath"'
#$scripttext = "\\CFSBCKITINFS01\software$\new-vmdeployment\Scripts\set-vmdeploymentbase.ps1"
#testing these two lines

#$scriptbatch = "Powershell.exe -executionpolicy remotesigned -File $scripttext"
#invoke-vmscript -ScriptText $scriptbatch -VM $requestedbuild.servername -guestcredential $guestcred -ScriptType bat

#invoke-vmscript -ScriptText $scriptlog -VM $requestedbuild.servername -guestcredential $guestcred
#Start-Sleep -s 1
#
#log "               Invoking PScript on VM" darkgreen
#invoke-vmscript -ScriptText $scripttext -VM $requestedbuild.servername -guestcredential $guestcred 
# Start-Sleep -s 1
log "               ... my work here is done." darkgreen


# _____________________ #
#                       #
# ___ SCRIPT END   ____ #
# _____________________ #

log "$(get-date) - Script completed, cleaning up" gray


#. write-verbose "Pausing before dumping variables"
pause

remove-variable '$ds' -erroraction SilentlyContinue
remove-variable '$csvpath' -erroraction SilentlyContinue
remove-variable '$cluster' -erroraction SilentlyContinue
remove-variable '$template' -erroraction SilentlyContinue
remove-variable '$datastores' -erroraction SilentlyContinue
remove-variable '$requestedbuild' -erroraction SilentlyContinue
remove-variable '$CSV' -erroraction SilentlyContinue


#. write-verbose "Setting ErrorAction Preference to continue for other scripts"
$ErrorActionPreference = "continue"
