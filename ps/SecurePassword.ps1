<#----------INTRODUCTION--------------#
Passwords in PowerShell can be stored in different forms. There are some of them:
String - Plain text strings. Used to store any text and of course can store passwords too. Strings are unsecure, 
they stored in memory as plain text and most cmdlets will not accept passwords in this form.
System.Security.SecureString - This type is like usual string, but its content are encrypted in memory. 

It uses reversible encryptiong so the password can be decrypted when needed, but only by principal that encrypted 
it. System.Management.Automation.PSCredential - PSCredential is class that composed from username (string) and 
password (SecureString). This is type that most cmdlets require for specifying credentials.

Converting from one type to other is not always an obvious task. There is some methods:#>

#CREATE SECURE STRING
$SecurePassword = Read-Host -Prompt "Enter password" -AsSecureString

#CONVERT FROM EXISTING PLAINTEXT VARIABLE
$PlainPassword = "password123"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force

<#CREATE PSCREDENTIALS
Assuming that you have password in SecureString form in $SecurePassword variable:
#>
$UserName = "ts\stadmin"
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword

<#EXTRACT PASSWORD FROM PSCREDENTIALS
Password can be easily obtained from PSCredential object using GetNetworkCredential method:
#>
$PlainPassword = $Credentials.GetNetworkCredential().Password

<#EXTRACT PASSWORD FROM SECURESTRING
If you have just simple SecureString with the password, you can construct PSCredentials object and 
extract password using previous method. Another method is this:
#>
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
#or:
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))

<#SAVING ENCRYPTED PASSWORD TO FILE OR REGISTRY
If you need to store password for script that runs in unattended mode by scheduler or using some other ways, 
it possible to save it to file system or registry in encrypted form. It is like string representation of SecureString. 
Only user that created this line can decrypt and use it, so when saving this value, use same account that script or service will use.
Converting SecureString variable to secure plain text representation
#>
$SecureStringAsPlainText = $SecurePassword = ConvertFrom-SecureString

<#
$SecureStringAsPlainText looks like this "ea32f9d30de3d3dc7fcd86a6a8f587ed9" (actually longer) and can be easily stored in file, 
registry property or any other storage. When script will need to obtain secure string object it can be done this way:
#>
$SecureString = $SecureStringAsPlainText  | ConvertTo-SecureString

<#----------BEST PRACTICES:--------------#
Of course best practice is when it possible to not use or ask passwords and try to use integrated Windows authentication.

When it not possible or when specifying different credentials is useful, cmdlets should accept it only in form of PSCredentials or 
(if username is not needed) as SecureString, but not plain text.

If you need to ask user for credential, use Get-Credential cmdlet. It uses standard Windows function to receive password in 
consistent and secure manner without storing it in memory as clear text.

Credentials should be passed to external system also in most secure way possible, ideally as PSCredentials too.

Password should not be saved to disk, registry or other not protected storage as plain text. Use plaintext representation of 
SecureString when possible.
#>