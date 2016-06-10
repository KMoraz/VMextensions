# We use write-verbose to turn on-and off comment-type data for this script, backing up original preferences. 
# All comments after this point are in write-verbose format
$oldverbose = $VerbosePreference

$VerbosePreference = "continue"

write-verbose 'We need to ensure that the variables are of type array, so we declare them specifically using the "@" delineator:'
$srvarray = @()
$srvcobject = @()

write-verbose 'Grab a big list, in this case the local services'
$srvcs = get-service

write-verbose 'We use the built-in logic of PS to cycle through each service in the list above'
foreach ($srvc in $srvcs
         ) {
            write-verbose "We create a line object of $($srvc.name) variable using built-in cmdlets"
            $srvcobject = new-object psobject -property @{Name= $srvc.name;Status= $srvc.status}
            write-verbose 'We add that line object to the array'                              
            $srvarray+=$srvcobject
           }

write-verbose 'We output that array to the screen'
$VerbosePreference = $oldverbose
