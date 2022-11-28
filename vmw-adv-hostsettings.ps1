Using module "..\lib\log-service.psm1"
Using module "..\lib\utils.psm1"
Using module "..\lib\vmware.psm1"

[CmdletBinding(SupportsShouldProcess=$true)]
Param(

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$vCenter
)