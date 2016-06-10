# Script to create local admin account on many computers
# Note: New local admin password will be saved to the log file. 
#       New local admin password must meet minimum password complexity requirements on target computers
# Sam Boutros - 7/16/2014 - V1.0
#
$CurrentAdmin = "administrator" # This can be an existing local admin account on the PCs or domain admin like "MyDomain\MyAdmin"
$NewAdmin = "MyNewAdmin" # New user name to be setup as local admin on target computers
$Targets = @("PC1","PC2","PC3") # List of target computers. Type it in here, or load it from file, or query AD, or...
# End Data Entry section
function log($string, $color) {
    if ($Color -eq $null) {$color = "white"}
    write-host $string -foregroundcolor $color   
    $temp = ": " + $string
    $string = Get-Date -format "yyyy.MM.dd hh:mm:ss tt"
    $string += $temp 
    $string | out-file -Filepath $logfile -append
}
#
$logfile = (Get-Location).path + "\Add-Admin_" + (Get-Date -format yyyyMMdd_hhmmsstt) + ".txt"
if (-not (Test-Path -Path ".\CurrentCred.txt")) {
    Read-Host ('Enter the pwd for current admin: "' + $CurrentAdmin + '" to be encrypted and saved to .\CurrentCred.txt for future script use:') -assecurestring | convertfrom-securestring | out-file .\CurrentCred.txt
}
$Pwd = Get-Content .\CurrentCred.txt | convertto-securestring
$CurrentCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CurrentAdmin, $Pwd
$NewCred = Read-Host ('Enter the pwd for new admin "' + $NewAdmin + '". Must meet minimum pwd complexity on each Target PC. This will be saved to the log file.')
foreach ($Target in $Targets) {
    $UserExists = Invoke-Command -ComputerName $Target -Credential $CurrentCred { param($Target,$NewAdmin,$NewCred)
        $objComputer = [ADSI]("WinNT://$Target,computer")
        $colUsers = ($objComputer.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)
        if ($colUsers -contains $NewAdmin) { 
            $data = "Yes"
            } else {
            $objOu = [ADSI]"WinNT://$Target"
            $objUser = $objOU.Create("User", $NewAdmin)
            $objUser.SetPassword($NewCred)
            $objUser.SetInfo() 
            $objOU = [ADSI]"WinNT://$Target/Administrators,group"
            $objOU.add("WinNT://$Target/$NewAdmin") 
            $data = "No"
        }
        return $data
    } -ArgumentList $Target,$NewAdmin,$NewCred
    if ($UserExists -eq "Yes") {
        log "User '$NewAdmin' already exists on '$Target', no changes are made on '$Target'.." Yellow
        } else {
        log "Attempting to create local admin '$NewAdmin' on '$Target' as local admin.." Cyan
        $UserExists = Invoke-Command -ComputerName $Target -Credential $CurrentCred { param($Target,$NewAdmin,$NewCred)
            $objComputer = [ADSI]("WinNT://$Target,computer")
            $colUsers = ($objComputer.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)
            if ($colUsers -contains $NewAdmin) {$data = "Yes"} else {$data = "No"}
            return $data
        } -ArgumentList $Target,$NewAdmin,$NewCred
        if ($UserExists -eq "Yes") {
            log "Successfully created local admin '$NewAdmin' with password '$NewCred' on '$Target'.." Green
            } else {
            log "Failed to create user '$NewAdmin' on '$Target', check if the porvided password '$NewCred' meets minimum pwd complexity requirements.." Yellow
        }
    }
}
If ($Error.Count -gt 0) {log "Errors encountered: $Error" Magenta} else {log "All local admin users successfully created." Cyan}
