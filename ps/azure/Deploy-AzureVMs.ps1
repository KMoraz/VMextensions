<#
Script to deploy azure cloud resources and VMs based on JSON templates and parameters
Azure IDs are stored in "config.xml" together with secured account passwords
#>

cls
#--------------------------------------------------
# Import modules and read config
#--------------------------------------------------
$ScriptName = $MyInvocation.MyCommand.Name
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
#$env:PSModulePath = $env:PSModulePath + ";${scriptPath}\..\mods"
#Import-Module Capita.Powershell.CASDS -ArgumentList $scriptPath -Force #-Verbose

$xml = [xml](Get-Content $scriptPath\config.xml)
if ($xml -eq $null)
{
	Out2Log ("Can't load config file [$scriptPath\config.xml]") -l_severity 2 -l_scriptname $ScriptName
	exit 2
}

#----Azure Acc-----#
$ad_user = $xml.AZConfig.AD.user
$ad_spassword = $xml.AZConfig.AD.spassword | ConvertTo-SecureString
$ad_cred = New-Object -typename System.Management.Automation.PSCredential -argumentlist $ad_user, $ad_spassword
#----Azure Env-----#
$az_env = $xml.AZConfig.AZ.env
$tenant_ID = $xml.AZConfig.AZ.tenant
#----Subcription-----#
#$sub_ID = $xml.AZConfig.SDLC.subscription
#$sub_Name = $xml.AZConfig.SDLC.name

#--------------------------------------------------
# Login-AzureRmAccount 
#--------------------------------------------------
#Add-AzureRmAccount -Credential $ad_cred -SubscriptionId $sub_ID
Out2Log "Logging into Azure..."  -l_severity 2
#Login-AzureRmAccount -Credential $ad_cred #-SubscriptionId $sub_ID

# After running Login-AzureRmAccount (Testing):
#[Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile.Save("$scriptPath\login")
# To load it up later without an actual interactive login:
#[Microsoft.WindowsAzure.Commands.Common.AzureRmProfileProvider]::Instance.Profile = New-Object Microsoft.Azure.Common.Authentication.Models.AzureRMProfile("$scriptPath\login")

#--------------------------------------------------
# Deployment with JSON configs located on GitLab
#--------------------------------------------------
function VM-Deploy {
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	[string]$Resource,
	[Parameter(Mandatory=$True)]
	[string]$Subscription,
    [Parameter(Mandatory=$True)]
	[string]$Git_Folder,
    [Parameter(Mandatory=$False)]
	[bool]$Test = $True
	)
    
    Out2Log "Started VM-Deploy -resource_Name: $Resource -Git_Folder: $Git_Folder -Test: $Test" -l_severity 6
    $Git = "https://almgitlabsvr01.casds.co.uk/core-infrastructure/infrastructure.iaas.v2/tree/master/vm/$Git_Folder"
    #$Git = "http://10.243.54.132/core-infrastructure/infrastructure.iaas.v2/tree/master/vm/$Git_Folder"
    Out2Log "Requesting page: $Git" -l_severity 6
    # Check if site is up
    try {
        $HTTP_Request = [System.Net.WebRequest]::Create($Git)
        $HTTP_Response = $HTTP_Request.GetResponse()
        $HTTP_Status = [int]$HTTP_Response.StatusCode

        if (-NOT ($HTTP_Status -eq 200)) 
        { 
            Out2Log ("Can't connect to GitLab: " + $_)  -l_severity 3
            break
        }
        else {
            try {
                # Locate Config Folder
                $request = Invoke-WebRequest $Git
                # Find full JSON filenames
                $template = $request.ParsedHtml.IHTMLDocument3_getElementsByTagName("a") | Where-Object{$_.nameProp -match "template.json$"} | Select -ExpandProperty nameProp
                $parameters = $request.ParsedHtml.IHTMLDocument3_getElementsByTagName("a") | Where-Object{$_.nameProp -match "parameters.json$"} | Select -ExpandProperty nameProp

                # Change URL to point to RAW text format
                $templateURL = "$Git/$template" -replace "tree","raw"
                $parametersURL = "$Git/$parameters" -replace "tree","raw"

                Out2Log "Using Template: ($template) with Parameters from: ($parameters)" -l_severity 6

                # Create JSON Configs
                $AZparameters = Invoke-WebRequest -Uri $parametersURL | ConvertFrom-Json | ConvertTo-Json
                $AZtemplate = Invoke-WebRequest -Uri $templateURL | ConvertFrom-Json | ConvertTo-Json
            
                <# Log Config Settings (Testing)
                Out2Log ("$parameters Variables:`n" + $AZparameters.parameters) -l_severity 6
                Out2Log ("$template Variables:`n" + $AZtemplate.variables) -l_severity 6
                Out2Log ("$template Parameters:`n" + $AZtemplate.parameters) -l_severity 6
                Out2Log ("$template Resources:`n" + $AZtemplate.resources) -l_severity 6
                #>
                $HTTP_Response.Close()
                }
            catch { Out2Log $_ -l_severity 3; break }
        }
    }
    catch { Out2Log ("Can't connect to GitLab: " + $_) -l_severity 3; break }

    if ($Test -eq 0) {
        try {
            Change-Subscription -sub_Name $Subscription
            Out2Log "Started Deployment on Subscription: $Subscription & Resource: $Resource" -l_severity 6
            New-AzureRmResourceGroupDeployment -ResourceGroupName $Resource -TemplateParameterFile $AZparameters -TemplateFile $AZtemplate
            Out2Log "Deployment Complete!" -l_severity 6
            }
        catch { Out2Log ("Test Deployment Failed: " + $_) -l_severity 1 }
    }
    else {
        try {
            Change-Subscription -sub_Name $Subscription
            Out2Log "Running Test Deployment on Subscription: $Subscription & Resource: $Resource" -l_severity 6
            Test-AzureRmResourceGroupDeployment -ResourceGroupName $Resource -TemplateParameterFile $AZparameters -TemplateFile $AZtemplate
            Out2Log "Test Deployment Successfull!" -l_severity 6
            }
        catch { Out2Log ("Deployment Failed: " + $_) -l_severity 1 }
    }
}
#VM-Deploy -Subscription "SDLC" -Resource "NSGTest" -Git_Folder "sdlcsimplevm" #-Test 0


function VM-DeployLocal {
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	[string]$Resource,
	[Parameter(Mandatory=$True)]
	[string]$Subscription,
    [Parameter(Mandatory=$True)]
	[string]$Folder_Name,
    [Parameter(Mandatory=$False)]
	[bool]$Test = $True
	)
    
    $JSONdir = "$scriptPath\..\..\vm\$Folder_Name"
    
    if (-NOT (Test-Path -path $JSONdir))
    { 
        Out2Log "Directory $JSONdir does not exist" -l_severity 3; break
    }
    else
    {
        $parameters = "$JSONdir\vm_sdlc_parameters.json"
        $template = "$JSONdir\vm_sdlc_template.json"

        Out2Log "Using Template: ($template) with Parameters from: ($parameters)" -l_severity 6

        $AZparameters = (Get-Content  $templateParam) -join "`n" | ConvertFrom-Json
        $AZtemplate = (Get-Content $tempFile) -join "`n" | ConvertFrom-Json
    }
    
    <#
    if ($Test -eq 0) {
        try {
            #Change-Subscription -sub_Name "SDLC"
            Out2Log "Started Deployment on Subscription: $Subscription & Resource: $Resource" -l_severity 6
            New-AzureRmResourceGroupDeployment -ResourceGroupName $Resource -TemplateParameterFile $AZparameters -TemplateFile $AZtemplate
            Out2Log "Deployment Complete!" -l_severity 6
            }
        catch { Out2Log ("Test Deployment Failed: " + $_) -l_severity 1 }
    }
    else {
        try {
            Change-Subscription -sub_Name "SDLC"
            Out2Log "Running Test Deployment on Subscription: $Subscription & Resource: $Resource" -l_severity 6
            Test-AzureRmResourceGroupDeployment -ResourceGroupName $Resource -TemplateParameterFile $AZparameters -TemplateFile $AZtemplate
            Out2Log "Test Deployment Successfull!" -l_severity 6
            }
        catch { Out2Log ("Deployment Failed: " + $_) -l_severity 1 }
    }#>
}
VM-DeployLocal -Subscription "SDLC" -Resource "NSGTest" -Folder_Name "sdlcsimplevm" #-Test 0