################
#On Load Module#
################
if ($args.Length -eq 0) 
{
	Write-Host @"
 
To load module execute: 

    Import-Module Capita.Powershell.CASDS -Force -ArgumentList (Split-Path -Parent `$MyInvocation.MyCommand.Definition) 
"@

	return
}

if (Test-Path $args[0]) {$scriptPath = $args[0]}
$curdate = Get-Date -UFormat "%Y%m%d"
$zone = [Regex]::Replace([System.TimeZoneInfo]::Local.StandardName, '([A-Z])\w+\s*', '$1')

###################
#Functions Section#
###################

function Out2Log
{
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	[string]$l_string,
	[Parameter(Mandatory=$True)]
	[int]$l_severity,
	[string]$l_module,
    [string]$l_scriptname
	)
	#if ($l_module -eq '') {$l_module = (Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name}
    $l_scriptname -replace '.ps1',''

	$l_levels = @{0="[Emergency]";1="[Alert] "; 2="[Critical]"; 3="[Error] "; 4="[Warning]"; 5="[Notice]"; 6="[Informational]"; 7="[Debug] "}

	if ((Test-Path -path $scriptPath\logs) -ne $true)
	{
		New-Item -ItemType directory -path $scriptPath\logs\ | Out-Null
	}

	$l_fname = "$curdate.log"
    $l_severity.ToString() + "`t" + (Get-Date).ToString("HH:mm:ss.fff") + " $zone`t" + $l_levels.Get_Item($l_severity) + "`t" + $l_string | 
        Out-File -Append -NoClobber -Encoding UTF8 -FilePath $scriptPath\logs\$l_fname

    # to add module name: "`t(" + $l_module + "::) + $l_string"
}

<#
function OutToLog
{
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	[string]$log,
	[string]$logfile
	)

	if ((Test-Path -path $scriptPath\logs) -ne $true)
	{
		New-Item -ItemType directory -path $scriptPath\logs\
	}

	if ($logfile -eq "")
	{
		$logfilename = $curdate + ".log"
	}
	else
	{
		$logfilename = $logfile
	}
        (Get-Date -f "dd.MM.yyyy HH:mm:ss.fff") + " " + $log | Out-File -Append -NoClobber -Encoding UTF8 -FilePath $scriptPath\logs\$logfilename
}#>


#---------------------------------------------------------------------------
# Add extension without JSON - meant for post VM deployment modifications
# REF: https://azure.microsoft.com/en-gb/blog/automate-linux-vm-customization-tasks-using-customscript-extension/
#---------------------------------------------------------------------------
function VM-Extension {

	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	[string]$ExtensionName,
	[string]$ScriptName,
    [string]$Params
	)

    #Identify the VM
	$vm = Get-AzureVM -ServiceName ‘MyServiceName’ -Name ‘MyVMName’
    #Specify the Location of the script and the command to execute
    $PublicConfiguration = '{"fileUris":["https://github.com/MyProject/Archive/MyPythonScript.sh"], "commandToExecute": "sh $ScriptName $Params" }'
	
    #Deploy the extension to the VM, pick up the latest version of the extension
	$ExtensionName = 'CustomScriptForLinux'
	$Publisher = 'Microsoft.OSTCExtensions'  
	$Version = '1.*' 
    
    Set-AzureVMExtension -ExtensionName $ExtensionName -VM $vm -Publisher $Publisher -Version $Version -PublicConfiguration $PublicConfiguration | Update-AzureVM
}

#--------------------------------------------------
# Select another Subscription after login
#--------------------------------------------------
function Change-Subscription {

	Param(
	[Parameter(Mandatory=$True)]
	[string]$sub_Name
	)

	$sub_ID = ($xml.AZConfig.$sub_name.subscription)
    Select-AzureRmSubscription -SubscriptionId $sub_ID
	Out2Log "Changing Azure Subscription to $sub_Name" -l_severity 6
}

#--------------------------------------------------
# Select another Resource Group after login
#--------------------------------------------------
function Change-ResourceGroup {

	Param(
	[Parameter(Mandatory=$True)]
	[string]$resource_Name
	)

    Set-AzureRmResourceGroup -Name $resource_Name
	$resource_Name + " is the selected Resource Group" | Write-Host
}

#--------------------------------------------------
# Stop single VM
#--------------------------------------------------
function Stop-VM {

	Param(
	[Parameter(Mandatory=$True)]
	[string]$resource_Name,
    [string]$VM_Name
	)

    Stop-AzureRmVM -ResourceGroupName $resource_Name -Name $VM_Name -Force -ErrorAction SilentlyContinue
}

#--------------------------------------------------
# Stop Multiple VMs within resource (in Parallel)
#--------------------------------------------------
workflow Stop-VMs {

	Param(
	[Parameter(Mandatory=$True)]
	[string]$resource_Name
	)

    $VMs = Get-AzureRmVM -ResourceGroupName "$resource_Name"

    Foreach -parallel ($VM in $VMs) {
    Stop-AzureRmVM -ResourceGroupName $resource_Name -Name $VM.Name -Force -ErrorAction SilentlyContinue
    }
}


function finish
{
	[CmdletBinding()]
	Param(
	[string]$exitcode
	)

	exit $exitcode
}

function Sendmail
{
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	[string]$relay,
	[Parameter(Mandatory=$True)]
	[string]$from,
	[Parameter(Mandatory=$True)]
	[string]$to,
	[string]$cc = '',
	[string]$subj = '',
	[string]$body = '',
	[switch]$html,
	[array]$attach
	)

	try
	{
		$msg = new-object Net.Mail.MailMessage
		$smtp = new-object Net.Mail.SmtpClient($relay)
	}
	catch
	{
		Out2Log $($_.Exception.Message) -l_severity 3
		$exitcode = 1
		finish $exitcode
	}

	$msg.From = $from
	if ($to -isnot [system.array]) {$msg.To.Add($to)}
	else
	{
		foreach ($email in $to)
		{
		  $msg.To.Add($email)
		}
	}
	$msg.subject = $subj
	$msg.body = $body
	$msg.IsBodyHtml = $html
	if ($cc -ne '') {$msg.CC.Add($cc)}
	
	if ($attach.count -ne 0)
	{
		foreach ($file in $attach)
		{
			$msg.attachments.add($file)
		}
	}

	try
	{
		$smtp.timeout = 600000
		$smtp.Send($msg)
	}
	catch
	{
		Out2Log $($_.Exception.Message) -l_severity 3
		$exitcode = 2
		finish $exitcode
	}

	$msg.Dispose()
	$smtp.Dispose()
}

function Push-OverLAN
{
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	[string]$src,
	[Parameter(Mandatory=$True)]
	[string]$dst,
	[Parameter(Mandatory=$True)]
	[string]$login,
	[Parameter(Mandatory=$True)]
	[string]$passwd,
	[switch]$recurse
	)

	if (($dst.Substring(0,2) -ne "\\") -and ($src.Substring(0,2) -ne "\\"))
	{
		Out2Log "Incorrect backup UNC host. Hostname should start with '\\'" -l_severity 3
		return $false
	}

	if ($dst[$dst.length-1] -ne "\") {$dst += "\"}
	if ($dst.Substring(0,2) -eq "\\"){$uncSrv = [string]::Join("\", $dst.split("\")[0..2])}
	else{$uncSrv = [string]::Join("\", $src.split("\")[0..2])}

	try
	{
		$net_res = net use $uncSrv $passwd /USER:$login 2>&1
		if ($net_res -like '*completed successfully*')
		{
			if ((Test-Path -path $dst) -ne $true)
			{
				New-Item -ItemType directory -path $dst | Out-Null
			}
			if ($recurse)
			{
				$res = copy-item $src $dst -Force -Recurse -PassThru -ErrorAction silentlyContinue
			}
			else
			{
				$res = copy-item $src $dst -Force -PassThru -ErrorAction silentlyContinue
			}
		}
		else
		{
			Out2Log ("NET answer: " + ([regex]::Replace($net_res, "`r|`n|`t| {2,}", ""))) -l_severity 3
			$res = $false
		}
	}
	catch
	{
		Out2Log $($_.Exception.Message) -l_severity 3
		$res = $false
	}
	finally
	{
		$net_res = net use $uncSrv /delete 2>&1
	}
	if ($res) {Out2Log ("Copied " + $res) -l_severity 6}
	return $res
}

function make_archive
{
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	[array]$files,
	[Parameter(Mandatory=$True)]
	[string]$arch_name,
	[switch]$move,
	[string]$user_switch = ''
	)

	$rar_path = "$PSScriptRoot\rar\rar.exe"
	$default_sw = " -m5 -tsa4 -tsm4 -tsc4 -ibck -inul -r -ed "

	if ($move -eq $true)
	{
		$sw1 = " m " + $default_sw
	}
	else
	{
		$sw1 = " a " + $default_sw
	}

	if ($user_switch -ne '') {$sw = $sw1 + $user_switch + " "}

	try
	{
		$rarproc = Start-Process -FilePath $rar_path -ArgumentList $sw -ErrorAction Stop -Wait -NoNewWindow -PassThru
		Out2Log ("Archived: " + $src + " to " + $dst) $logfil
	}
	catch
	{
		OutToLog ("[ERROR] RAR: " + $Error[0]) ($curdate + "_error.log")
		OutToLog ("[ERROR] " + $argv) ($curdate + "_error.log")
	}
	return $winrarproc.exitcode
}

function TestPort
{
	Param(
	[parameter(ParameterSetName='ComputerName', Position=0)]
	[string]$ComputerName,
	[parameter(ParameterSetName='IP', Position=0)]
	[System.Net.IPAddress]$IPAddress,
	[parameter(Mandatory=$true , Position=1)]
	[int]$Port,
	[parameter(Mandatory=$true, Position=2)]
	[ValidateSet("TCP", "UDP")][string]$Protocol
	)

	$Result = $false

	$RemoteServer = If ([string]::IsNullOrEmpty($ComputerName)) {$IPAddress} Else {$ComputerName};

	If ($Protocol -eq 'TCP')
	{
		$test = New-Object System.Net.Sockets.TcpClient;
		Try
		{
			Out2Log ("Connecting to " + $RemoteServer + ":" + $Port + " (TCP)..") -l_severity 6
			$test.Connect($RemoteServer, $Port)
			Out2Log ("Connection successful") -l_severity 6
			$Result = $True
		}
		Catch
		{
			Out2Log ("Connection failed") -l_severity 6
		}
		Finally
		{
			$test.Dispose();
		}
	}

	If ($Protocol -eq 'UDP')
	{
		$test = New-Object System.Net.Sockets.UdpClient;
		Try
		{
			Out2Log ("Connecting to " + $RemoteServer + ":" + $Port + " (UDP)..") -l_severity 6
			$test.Connect($RemoteServer, $Port)
			Out2Log ("Connection successful") -l_severity 6
			$Result = $True
		}
		Catch
		{
			Out2Log ("Connection failed") -l_severity 6
		}
		Finally
		{
			$test.Dispose();
		}
	}
	return $Result
}
<#
function MySQL-Connect
{
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	[string]$MySQLHost,
	[int]$MySQLPort,
	[Parameter(Mandatory=$True)]
	[string]$user,
	[Parameter(Mandatory=$True)]
	[string]$pass,
	[int]$def_timeout
	)
	if ($MySQLPort -eq 0) {$MySQLPort = 3306}
	if ($def_timeout -eq 0) {$def_timeout = 600}
	
	# Load MySQL .NET Connector Objects 
	if ((Test-Path $PSScriptRoot\MySql.Data.dll) -ne $true)
	{
		Out2Log ("Can't find library [$PSScriptRoot\MySql.Data.dll]") -l_severity 3
		$result = $false
	}
	else
	{
		try
		{
			[void][System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\MySql.Data.dll")
		}
		catch
		{
			Out2Log $($_.Exception.Message) -l_severity 3
			$result = $false
		}
	}

	# Open Connection 
	$connStr = "server=" + $MySQLHost + ";port=" + $MySQLPort.ToString() + ";uid=" + $user + ";pwd=" + $pass + ";DefaultCommandTimeout=" + $def_timeout.ToString() + ";"
	try
	{
		$result = New-Object MySql.Data.MySqlClient.MySqlConnection($connStr) 
		$result.Open()
	}
	catch
	{
		Out2Log "Unable to connect to MySQL server..." -l_severity 3
		Out2Log $_.Exception.Message -l_severity 3
		$result = $false
		Write-Host $_.Exception.Message
		exit
	}
	if ($result -ne $false) {Out2Log ("Connected to MySQL host " + $MySQLHost + ":" + $MySQLPort) -l_severity 6}
	return $result
}

function MySQL-Disconnect
{
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	$conn
	)
	
	foreach ($val in $conn.ConnectionString.Split(";"))
	{
		$conn_params += @{$val.Split("=")[0]=$val.Split("=")[1]}
	}
	try
	{
		$conn.Close()
		Out2Log ("Disconnected from MySQL host " + $conn_params.Get_Item("Server") + ":" + $conn_params.Get_Item("Port")) -l_severity 6
	}
	catch
	{
		Out2Log $($_.Exception.Message) -l_severity 3
	}
}

function MySQL-nonQuery
{ 
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	$conn,
	[Parameter(Mandatory=$True)]
	[string]$query,
	[bool]$err_exit = $true
	)

	# NonQuery - Insert/Update/Delete query where no return data is required
	try
	{
		$command = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $conn)
		$RowsInserted = $command.ExecuteNonQuery()
	}
	catch
	{
		Out2Log "Error using SQL query" -l_severity 3
		Out2Log $query -l_severity 3
		Out2Log $($_.Exception.Message) -l_severity 3
		if ($err_exit -eq $true)
		{
			$exitcode = 5
			finish $exitcode
		}
	}
	Out2Log ("Sql query: " + [regex]::Replace($query, "`r|`n|`t| {2,}", " ")) -l_severity 7
	Out2Log ("Rows Affected: " + $RowsInserted) -l_severity 6
	$command.Dispose() | out-null
	return $RowsInserted
} 

function MySQL-Query
{ 
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$True)]
	$conn,
	[Parameter(Mandatory=$True)]
	[string]$query,
	[bool]$err_exit = $true
	)

	$command = New-Object MySql.Data.MySqlClient.MySqlCommand($query, $conn)
	$dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($command)
	$dataSet = New-Object System.Data.DataSet
	try
	{
		$dataAdapter.Fill($dataSet, "data") | out-null
	}
	catch
	{                                                        
		Out2Log "Error using SQL query" -l_severity 3
		Out2Log $query -l_severity 3
		Out2Log $($_.Exception.Message) -l_severity 3
		if ($err_exit -eq $true)
		{
			$exitcode = 5
			finish $exitcode
		}
	}
	Out2Log ("Sql query: " + [regex]::Replace($query, "`r|`n|`t| {2,}", " ")) -l_severity 7
	$command.Dispose() | out-null
	return $dataSet.Tables["data"]
}

Set-Alias -Name Connect-MySQL -Value MySQL-Connect
Set-Alias -Name Disconnect-MySQL -Value MySQL-Disconnect
Set-Alias -Name Invoke-MySQLNonQuery -Value MySQL-nonQuery
Set-Alias -Name Invoke-MySQLQuery -Value MySQL-Query

Export-ModuleMember -Function * -Alias *

#>