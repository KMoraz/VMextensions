$vms = import-csv 'c:\scripts\vmspaceissues.csv'

$vms | % {  $busowner = Get-Annotation -name 'service owner (business)' $_.name ; if($busowner.value -eq $null){$busowner.value = "Unknown"}
            $itowner = Get-Annotation -name 'service owner (IT)' $_.name ; if($itowner.value -eq $null){$itowner.value = "Unknown"}
            $vmandowner = @{"Server Name" = $_.Name;
                            "Owner" = $busowner.value;
                            "IT" = $itowner.value
                           }
            new-object -typename psobject -property $vmandowner -outvariable completedvm; 
            $vmsandowners += $completedvm
         }

$completedvm | export-csv c:\scripts\vmspaceissues_withinfo.csv -NoTypeInformation -Force