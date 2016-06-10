Configuration CFSTelnetclient 
{ 
  param ($MachineName)

  Node $MachineName 
  { 
    #Install a TelnetClient
    WindowsFeature TelnetClient 
    { 
      Ensure = “Present” 
      Name = “Telnet-Client” 
    } 
  } 
}