
write-verbose "--Get AD User"
$user = read-host "Enter AD User"
$user = $user -replace '\s',''

write-verbose "--Getting AD Creds"
$password = read-host "Enter AD PW:" -AsSecureString

write-verbose "--converting shortname to securestring object"
$secure = ConvertTo-SecureString $password -force -asplaintext
write-verbose "... converted."

write-verbose "--converting securestring object to bytes"
$bytes = ConvertFrom-SecureString $secure 
write-verbose "... converted."

write-verbose '$password is now encrypted as $bytes'
pause

write-verbose "--converting bytestring object to securestring"
$scrpassword = ConvertTo-SecureString -string $bytes 
write-verbose "... converted."


get-aduser -identity $user -credential adcfs\wayerst -password $scrpassword

$VerbosePreference = silentlycontinue
