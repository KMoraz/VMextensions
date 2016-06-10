# Set Firewall Rule and Port NAT for a Container


# ______________________ #
#                        #
# _ SET CONTAINER NATFW_ #
# ______________________ #


Function Get-ContainerList {
  <#
  .SYNOPSIS
  Get a list of containers on the current host and NAT info
  .DESCRIPTION
  This function uses the Get-NetStaticMapping and custom function Get-ContainerIP 
  to interrogate each Container for it's IP address and cross reference against 
  NAT rules that exist. 
  .EXAMPLE
  Get-ContainerList
  .PARAMETER -
  No Parameters
  #>
  [CmdletBinding()]
  param
  ()

### This refers to GET-CONTAINERIP function custom written by WAyerst. This file should be in the c:\scripts location on this server
### Please run the .ps1 to register this function ahead of time

if ((get-command get-containerip*) -eq $null)
     {throw "Get-ContainerIP missing!"}


$containernattable = $null
$containernattable = @()

# Host and Nat Array
 #Define Table Array

 $containerlist = get-container

$containerlist | % {
 
 # Grab Container IP
 $containerip = $null
 $containerip = (get-containerip -containername $_.name).ip
 # Grab Relevant Nats
 $mapping = $null
 $mapping = get-netnatstaticmapping | where-object {$_.internalipaddress -eq $containerip}

 # Get Nat Details
 if ($mapping.internalipaddress -eq $null)
        {$HostNATPort = $null;
         $ContainerPort = $null}
else    {$HostNATPort = $($mapping.externalport);
         $ContainerPort = $($mapping.internalport)}

 # Build Container Details Line
 $line = New-Object -TypeName PSObject -Property `
                @{
                "Name" = $_.name;
                "State" = $_.state;
                "IP" =  $containerip;
                "ContainerPort" = $ContainerPort;
                "HostNATPort" =  $HostNATPort
                 }
$containernattable += $line
                }


#Do something with the Array
$containernattable | select name,state,ip,containerport,hostnatport
}