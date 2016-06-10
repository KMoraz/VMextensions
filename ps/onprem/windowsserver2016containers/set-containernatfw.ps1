# Set Firewall Rule and Port NAT for a Container


# ______________________ #
#                        #
# _ SET CONTAINER NATFW_ #
# ______________________ #


function Set-ContainerNATFW {
  <#
  .SYNOPSIS
  Define a port (used by a container) to be configured in NAT and FW Rules
  .DESCRIPTION
  This function recieves the name of a container and the port it is expecting to recieve
  requests on, as well as an external port that the container host will listen on. It then
  sets up both the netnatstaticmapping and the firewallrules to permit this traffic. 
  .EXAMPLE
  Set-ContainerNATFW -containername iisdefault3 -containerport 80 -natport 8080
  .PARAMETER containername
  The container name to configure, just one!
  .PARAMETER containerport
  The port that the application or service on the container is listening on. 
  .PARAMETER natport
  The port which the container host will listen on, in order to pass it through to the
  container itself. This is the port that external resources will query
  #>
  [CmdletBinding()]
  param
  (
    # Parameter for Container
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    HelpMessage='What container would you like to set rules for?')]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(3,30)]
    [string[]]$containername,
    
    # Parameter for Container Port
    [parameter(Mandatory=$true,
    HelpMessage='What port is listening inside the container?')]
            [ValidateRange(0,50000)]
            [ValidateNotNullOrEmpty()]
            [uint16]$containerport,
    
    # Parameter for Host Port
    [parameter(Mandatory=$true,
    HelpMessage='What port should the host listen on and provide NAT for?')]
            [ValidateRange(0,50000)]
            [ValidateNotNullOrEmpty()]
            [uint16]$NATport
      )

### This refers to GET-CONTAINERIP function custom written by WAyerst. This file should be in the c:\scripts location on this server
### Please run the .ps1 to register this function ahead of time

if ((get-command get-containerip*) -eq $null)
     {throw "Get-ContainerIP missing!"}



## Check Container Exists
if((get-container -name $containername) -eq $null)
            {throw "No Such Container"}

## Start Container if it's not Running
if((get-container -name $containername).state -ne "Running")
            {
            try {start-container $containername}
            catch {throw "Container not Running, and unable to start"}
            }    

# Put the output of the get-containerip into a variable
$containerip = get-containerip $containername



#######################
#######################
#######################
##
## Need to set up confirmation to overwrites of existing rules!!
##
##
#######################
#######################
#######################



#
# Check FW Rule
#
$CheckFW = Show-NetFirewallRule | Where LocalPort -eq $NATPort | ForEach-Object {$_.LocalPort}

# If the Port Exists, skip everything here
if ($CheckFW -gt 0) 
        {
            Write-warning "NAT Port already present on Container Host Firewall, Task Skipped."
            # Dirty output table
            Show-NetFirewallRule | Where LocalPort -eq $NATPort | select instanceid,localport | out-host
        } 
   else 
        {
            New-NetFirewallRule -Name "Container NAT $ContainerName" -DisplayName "Container NAT $ContainerName" -Description "Container NAT from $ContainerPort on Port $NATPort" -Protocol tcp -LocalPort $NATPort -Action Allow
            Write-Host "Container Host Firewall Rule for $ContainerName created on NAT port $NATPort" -ForegroundColor cyan
        }
#
# Check NAT Rule
#
$CheckNAT = get-netnatstaticmapping | Where externalport -eq $NATPort

#
# If a matching rule is found, skip everything here
#
if ($($CheckNAT.internalipaddress) -eq $($containerip.ip) -and $($CheckNAT.internalport) -eq $($containerport)) 
            {
                Write-warning "NAT Rule with same Port and IP already exists. Task skipped"
                $checknat | out-host
            } 
    else 
            {
                # If a rule is found which matches the internal port skip everything here
                #
                if ($($CheckNAT.internalport) -eq $($containerport))
                            {
                                write-warning "NAT Rule with same Port already exists Task skipped"
                                $checknat | out-host
                            }
                else {
                                Add-NetNatStaticMapping -NatName "NAT" -Protocol TCP -ExternalPort $NATPort -ExternalIPAddress 0.0.0.0 -InternalPort $ContainerPort -InternalIPAddress $ContainerIP.ip
                                Write-Host "NAT Rule for Container $ContainerName created from Host NAT Port $NATport to Container IP $($ContainerIP.ip) local port $containerport" -ForegroundColor cyan
                     }
            }

 }