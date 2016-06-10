# Flush and Rebuild Container Script

# _____________________ #
#                       #
# ___ LOG FUNCTION ____ #
# _____________________ #
#
# This is our logging function, it must appear above the code where you are trying to use it.

# Define a new log name
$logfile = "c:\scripts\logs\container_$(get-date -uformat %d%m%y).log"

function log($string, $color)
{
   if ($Color -eq $null) {$color = "white"}
   write-host $string -foregroundcolor $color
   $string | out-file -Filepath $logfile -append
}


# _____________________ #
#                       #
# _ GET CONTAINER IP  _ #
# _____________________ #

Function Get-ContainerIP ($container)
        {
        if((get-container -name $container).state -like "Running")
            {
            try  {
                $(((invoke-command -containername $container {ipconfig} | sls "IPv4 Address").line.split(":",2))[1]).trim()
                 }
            catch{
                write-error "Container is not responsive to IPconfig commmand!"
                 }
            }
        else
            {
            write-error "Container is not Running, unable to interrogate!"
        }
}

clear-host


$container = read-host "Enter the name of the container to redeploy"
$containerimage = "IISCapita"
$switch = "NAT"
log  "$container will be deleted and redeployed from $containerimage image" cyan
log  "press ctrl+c to abort now!" cyan

pause
$enddtime = $null
$starttime = $null

$starttime = Get-Date -format HH:mm:ss

log "$(get-date) - Starting Flush Process"

if(get-container -name $container)
{
        if((get-container -name $container).state -like "Running")
            {   log "$(get-date) - Stopping Container Subroutine" yellow
                log  "              Getting internal IP for $container" darkyellow
                    try   {
                            $originalip = get-containerip $container
                             log "              ...Success! ( $originalip )" darkyellow             
                          }
                    catch {
                            log "              ...Unable to get IP" darkyellow
                          }
                log "              Stopping $container..." darkyellow
                stop-container $container 
                log "              ...Stopped" darkyellow
                log "$(get-date) - Stopping Container Subroutine Complete" darkyellow
            }    

log "$(get-date) - Removing Container Subroutine" yellow
try {remove-container $container -force;
     log "              $container successfully removed" darkyellow}
catch {throw}
}
log "$(get-date) - Removing Container Subroutine Complete" yellow

log  "$(get-date) - Deploying Container Subroutine" green
log "              Name: $container" darkgreen
log "              Image: $containerimage" darkgreen
log "              Switch: $switch" darkgreen
try {new-container -name $container -containerimagename $containerimage -switch $switch;
 log "$(get-date) - Deploying Container Subroutine Complete" green}
catch {throw}
     
log "$(get-date) - Restarting Container Subroutine" cyan
log "              Starting $container" darkcyan
start-container $container

log  "              Getting internal IP for $container" darkcyan
                    try   {
                            $newip = get-containerip $container
                             log "              ...Success! ( $newip )" darkcyan             
                          }
                    catch {
                            log "              ...Unable to get IP" darkcyan
                          }
log "$(get-date) - Restarting Container Subroutine Complete" cyan

$endtime = Get-Date -format HH:mm:ss
$TimeDiff = New-TimeSpan $starttime $endtime
if ($TimeDiff.Seconds -lt 0) {
	$Hrs = ($TimeDiff.Hours) + 23
	$Mins = ($TimeDiff.Minutes) + 59
	$Secs = ($TimeDiff.Seconds) + 59 }
else {
	$Hrs = $TimeDiff.Hours
	$Mins = $TimeDiff.Minutes
	$Secs = $TimeDiff.Seconds }
$Difference = '{0:00}:{1:00}:{2:00}' -f $Hrs,$Mins,$Secs


log "Summary:"
log "              Name: $container" 
log "              Image: $containerimage"
log "              Switch: $switch"
log "              IP: $newip"
if ($newip -ne $originalip) {log "IP CHANGED! Update NAT RULES!" red}

log "Elapsed time: $Difference" 


write-host ""
write-host ""

