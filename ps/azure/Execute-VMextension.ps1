#---------------------------------
# Linux VM Customization - Running scripts stored in GitHub
# REF: https://azure.microsoft.com/en-gb/blog/automate-linux-vm-customization-tasks-using-customscript-extension/
#---------------------------------

#Identify the VM
$vm = Get-AzureVM -ServiceName ‘MyServiceName’ -Name ‘MyVMName’
#Specify the Location of the script and the command to execute
$PublicConfiguration = '{"fileUris":["https://github.com/MyProject/Archive/MyPythonScript.py"], "commandToExecute": "python MyPythonScript.py" }' 

#Deploy the extension to the VM, pick up the latest version of the extension
$ExtensionName = 'CustomScriptForLinux'  
$Publisher = 'Microsoft.OSTCExtensions'  
$Version = '1.*' 
Set-AzureVMExtension -ExtensionName $ExtensionName -VM  $vm -Publisher $Publisher -Version $Version -PublicConfiguration $PublicConfiguration  | Update-AzureVM