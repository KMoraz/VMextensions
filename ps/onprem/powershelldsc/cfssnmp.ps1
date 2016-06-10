Configuration CFSSNMP 
{ 
  param ([Parameter(Mandatory)]
        $MachineName
        )

  Node $MachineName 
  { 
    #Install the SNMP service
    WindowsFeature SNMP-service
    { 
      Ensure = “Present” 
      Name = “SNMP-service” 
    } 
  } 
}