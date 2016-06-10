
# Get Container, IP and NAT information for this Host

# _____________________ #
#                       #
# _ GET CONTAINER IP  _ #
# _____________________ #

Function Get-ContainerIP {
  <#
  .SYNOPSIS
  Interrogate the Container for it's IP address configuration
  .DESCRIPTION
  This function invokes a command on the container, then processes through the list of IP
  addresses to get the primary and returns it
  .EXAMPLE
  Get-ContainerIP -containername iisdefault3
  .PARAMETER containername
  The container name to check, just one!
  #>
  
  [CmdletBinding()]
  param
  (
    # Parameter for Container
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    HelpMessage='What container would you like to interrogate?')]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(3,30)]
    [string[]]$containername
  )
  
 $objcontainer = get-container $containername

        if($objcontainer.state -ne "Running")
             {$containerip = $null}
        else {$TmpIP = Invoke-Command -Containername $objcontainer.name {Get-NetIPAddress}}

        foreach ($ip in $TmpIP) { 
                                    if   ($ip.PrefixOrigin -ne 1)
                                         {} 
                                    else {$ContainerIP = $ip.IPv4Address} 

                                }

 $output = New-Object -TypeName PSObject -Property `
                @{
                "ID" = $objcontainer.id
                "Name" = $objcontainer.name;
                "IP" = $containerip
                }
$Output | select name,ip
}


