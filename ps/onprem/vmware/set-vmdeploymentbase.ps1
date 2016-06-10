# _____________________ #
#                       #
# ___ LOG FUNCTION ____ #
# _____________________ #
#
# This is our logging function, it must appear above the code where you are trying to use it.


$logfile = "\\CFSBCKITINFS01\software$\IT Core Infrastructure\Scripts\$($requestedbuild.servername)_OS.log"
function log($string, $color)
{
   if ($Color -eq $null) {$color = "white"}
   write-host $string -foregroundcolor $color
   $string | out-file -Filepath $logfile -append
}

log "I'm ALIIIIVE!" 

# Local System Information v3
# Shows details of currently running PC

$computerSystem = Get-CimInstance CIM_ComputerSystem
$computerBIOS = Get-CimInstance CIM_BIOSElement
$computerOS = Get-CimInstance CIM_OperatingSystem
$computerCPU = Get-CimInstance CIM_Processor
$computerHDD = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID = 'C:'"

log "System Information for: $($computerSystem.Name)"
log "HDD Capacity: $($computerHDD.Size/1GB)"
log "RAM: $($computerSystem.TotalPhysicalMemory/1GB)"
log "Operating System: $($computerOS.caption), Service Pack: $($computerOS.ServicePackMajorVersion)"
log "User logged In: $($computerSystem.UserName)"
log "Last Reboot: $($computerOS.LastBootUpTime)"