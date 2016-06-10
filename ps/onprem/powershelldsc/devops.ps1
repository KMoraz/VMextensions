Configuration ContosoWebsite 
{ 
  param ($MachineName)

  Node $MachineName 
  { 
    #Install a TelnetServer
    WindowsFeature TelnetServer 
    { 
      Ensure = “Present” 
      Name = “Telnet-Server” 
    } 
  } 
}