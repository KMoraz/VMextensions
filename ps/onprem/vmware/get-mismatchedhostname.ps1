$IncludeFQDN = $false
 
Get-VM | Where { $_.PowerState -eq "PoweredOn" } | Foreach {
    If ($IncludeFQDN) {
      $Name = $_.Guest.Hostname
   } Else {
      $Name = (([string]$_.Guest.HostName).Split("."))[0]
   }
    If ($_.Name -ne $Name) {
        If ($_.Guest.Hostname) {
            Write "VM name '$($_.Name)' is not the same as the hostname $Name"
              } Else {
            Write "Unable to read hostname for $($_.Name) - No VMTools ?"
        }
    } 
    }