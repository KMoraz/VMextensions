 
 #Add Active Directory Snapin
  
 #Get a list of AD computers with Server OS, select only the name and export to pclist.txt
 Get-ADComputer -filter {operatingsystem -like "*Server*"} `
   | select name | sort name `
   | out-file -filepath "c:\scripts\temp\pclist.txt" -force
