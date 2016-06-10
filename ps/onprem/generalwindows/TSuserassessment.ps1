# We use write-verbose to turn on-and off comment-type data for this script, backing up original preferences. 
# All comments after this point are in write-verbose format

$oldverbose = $VerbosePreference

#$VerbosePreference = "continue"

write-verbose 'We need to ensure that the variables are of type array, so we declare them specifically using the "@" delineator:'
$aduseritem = @()
$aduserlist = @()

write-verbose 'Grab a list of users'
$tsusers = get-content f:\newtsusers.txt

write-verbose 'We use the built-in logic of PS to cycle through each service in the list above'
foreach ($tsuser in $tsusers
         ) {$aduser = get-aduser $tsuser -properties cn,description,office,lastlogondate 
            write-verbose "We create a line object of $($_.name) variable using built-in cmdlets"
            $aduseritem = new-object psobject -property @{Name = $aduser.cn
                                                          Title = $aduser.description
                                                          Office = $aduser.office
                                                          LastLogon = $aduser.lastlogondate}
            write-verbose 'We add that line object to the array'                              
            $aduserlist+=$aduseritem
           }

write-verbose 'We output that array to the screen'
$VerbosePreference = $oldverbose
