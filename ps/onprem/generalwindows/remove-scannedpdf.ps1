$oldverbose = $VerbosePreference
$VerbosePreference = "continue"

# We define the $paths variable as an array
write-verbose "--- Defining $Path Variable"
$paths = @()

# This Cmdlet will remove PDF files recursively from paths you specify
# The default is c:\temp, but you can add as many as you wish by removing
# the # mark that prefixes each line.

# Add your paths below. There is error catching to ensure you are listing 
# folders, but please do your best to ensure they follow the commented 
# examples.
write-verbose "--- Setting Path Variables"
$paths += "c\temp2"
$paths += "c:\temp"
# $paths += "c:\temp"
# $paths += "c:\temp"
# $paths += "c:\temp"


Write-verbose "--- Starting Path Loop"
foreach ($path in $paths) { Write-verbose "----- Testing $($path) is a Folder"
                            IF   (-NOT (Test-Path $Path -PathType 'Container')) 
                                         { 
                                             write-verbose "----- Displaying Error on Invalid Path"
                                             Write-Error "$($Path) is not a valid folder, not processing this location" 
                                         } 
                            ELSE 
                                         {   Write-verbose "----- Getting contents of $($path) Recursively"
                                             Get-childitem $path -include *.pdf -recurse |
                                             Foreach ($_) {Write-verbose "------- Deleting contents of Folder Loop"
                                                            remove-item $_.fullname}
                                         }
                          }

write-verbose "--- Clearing Variables"
$paths = out-null
$path = out-null
# Cmdlet help available here: https://technet.microsoft.com/library/hh849765.aspx

$VerbosePreference = $oldverbose