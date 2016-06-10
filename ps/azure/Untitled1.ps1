cls
function VM-Deploy {
	Param(
	[Parameter(Mandatory=$True)]
	[string]$Git_Folder
	)

# Use remote JSON configs via HTTP (GitLab):
    #$Git = "http://10.243.54.132/core-infrastructure/infrastructure.iaas.v2/tree/master/vm/$Git_Folder"
	$Git = "https://almgitlabsvr01.casds.co.uk/core-infrastructure/infrastructure.iaas.v2/tree/master/vm/$Git_Folder"
    $Git
	#$request = Invoke-WebRequest $Git
	
    #$AZparameters = Invoke-WebRequest -Uri '$Git + $Git_Folder + /*_parameters.json' | ConvertFrom-Json
    #$AZtemplate = Invoke-WebRequest -Uri "$Git + $Git_Folder + /*_template.json" | ConvertFrom-Json
    $filename = $request.Document.IHTMLDocument3_getElementsByTagName("a") | Where-Object{$_.nameProp -match "template.json$"} | Select -ExpandProperty nameProp
	#$xe.Document.IHTMLDocument3_getElementsByTagName("Input") 
    $fileurl = "$Git/$filename" -replace "tree","raw"
    $fileurl #-replace "tree","raw"
	
	#Invoke-WebRequest -Uri $fileurl

    #$request = $null
	#$filename = $null
    #$AZparameters.parameters
    #Out2Log $AZtemplate.variables -l_severity 6
    #Out2Log $AZtemplate.parameters -l_severity 6
    #Out2Log $AZtemplate.resources -l_severity 6
	
    #Test-AzureRmResourceGroupDeployment -ResourceGroupName $resource_Name -TemplateParameterFile $templateParam -TemplateFile $tempFile
    #New-AzureRmResourceGroupDeployment -ResourceGroupName $resource_Name -TemplateParameterFile $templateParam -TemplateFile $tempFile
}
VM-Deploy -Git_Folder "sdlcsimplevm"
