
Get-ADUser -filter * -properties scriptpath, homedrive, homedirectory | where-object {$_.enabled -eq "False" -or $_.description -like "*disabled*"} | where-object {$_.name -notlike "svc*" -and -notlike "sa*"} | ft


# Get-ADUser -filter * -properties scriptpath, homedrive, homedirectory | ft Name, scriptpath, homedrive, homedirectory > C:\scripts\outputs\AD_usersprofiles.txt