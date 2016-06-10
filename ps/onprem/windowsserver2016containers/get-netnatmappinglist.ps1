



#######################
#######################
#######################
##
## Need to set up list first and THEN compare
##
##
#######################
#######################
#######################



# ______________________ #
#                        #
# _ GET MAPPINGS LIST _ #
# ______________________ #

Function Get-NetNatMappingList ()
        {

# Clear Variables
$staticmappingstable = $null
$staticmappingstable = @()
$containerlist = $null

# Get arrays to compare
$staticmappings = get-netnatstaticmapping
$containerlist = get-containerlist


foreach ($staticmapping in $staticmappings)
    {
 
# Grab Container Matching Mapping IP
$linkedcontainer = ($containerlist | where-object {$_.IP -eq $staticmapping.internalipaddress})


 # Build Container Details Line
 $staticmappingline = New-Object -TypeName PSObject -Property `
                @{
                "ID" = $staticmapping.StaticMappingID;
                "Container" = $linkedcontainer.name;
                "ContainerIP" = $linkedcontainer.IP;
                                        "Protocol" = $staticmapping.protocol;
                            "ExternalIPAddress" = $staticmapping.externalipaddress;
                            "InternalIPAddress" = $staticmapping.internalipaddress;
                            "ContainerPort" = $staticmapping.internalport;
                            "HostNATPort" =  $staticmapping.externalport
                }
$staticmappingstable += $staticmappingline
     }


#Do something with the Array
$staticmappingstable | select ID,Container,ContainerIP,InternalIPAddress,ExternalIPAddress,ContainerPort,HostNATPort
}