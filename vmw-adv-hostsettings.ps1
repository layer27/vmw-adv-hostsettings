Using module ".\lib\module-instance.psm1"


[CmdletBinding(SupportsShouldProcess=$true)]
Param(

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$vCenter,
    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string[]]$vmHosts,
    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$Configuration,
    [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
    [switch]$ReportOnly
)


$instance = [ModuleInstance]::new()


