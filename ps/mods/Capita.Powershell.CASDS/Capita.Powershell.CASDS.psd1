#
# Module manifest for module 'Capita.Powershell.CASDS'
#
# Generated by: Sadik Tekin
#
# Generated on: 11/05/2016
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '1.0.3.0'

# ID used to uniquely identify this module
GUID = 'f4116903-4ab1-4910-864a-cc10a146e3ce'

# Author of this module
Author = 'Sadik Tekin'

# Company or vendor of this module
CompanyName = 'Capita PLC'

# Copyright statement for this module
Copyright = '(c) 2016 Sadik Tekin. All rights reserved.'

# Description of the functionality provided by this module
# Description = ''

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('Capita.Powershell.CASDS.psm1')

# Functions to export from this module
FunctionsToExport = @(
	'Out2Log',
#	'OutToLog',
#	'finish',
	'Sendmail',
	'Push-OverLAN',
	'TestPort'
	'VM-Extension',
	'Change-Subscription',
	'Change-ResourceGroup',
	'Stop-VM',
	'Stop-VMs')
<#
	'MySQL-Connect',
	'MySQL-Disconnect',
	'MySQL-nonQuery',
	'MySQL-Query'
#>

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

<# Aliases to export from this module
AliasesToExport = @(
	'Connect-MySQL',
	'Disconnect-MySQL',
	'Invoke-MySQLNonQuery',
	'Invoke-MySQLQuery')
#>
# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

