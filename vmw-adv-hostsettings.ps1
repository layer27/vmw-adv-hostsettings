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
    [string]$User,
    [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
    [string]$Passwd,
    [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
    [switch]$ReportOnly
)

try {
    # Import Modules
    Import-Module VMware.VimAutomation.Core
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false | Out-Null
} catch {
    throw "Error importing VMware modules"
    break
}

# Create instance of module to run
try {
    $instance = [ModuleInstance]::new()
} catch {
    throw $_
    break
}

# Connect to vCenter
try {
    if ($User -and $Passwd) {
        $pw = ConvertTo-SecureString $Passwd -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential ($User, $pw)
    } else  {
        $credential = Get-Credential -Message "Enter Credentials for vCenter: $vCenter"
    }
    $instance.connectVcenter($vCenter, $credential)
} catch {
    throw $_
    break
}

# Read Configuration File
try {
    $config = $instance.readConfigFile($Configuration)
} catch {
    throw $_
    break
}


# Process Advanced Properties
foreach ($vmHost in $vmHosts) {

    $instance.debug("Evaluating advanced properties for host: $vmHost")
    # Generate host data evaluation
    $data = $instance.evalHostProperties($vmHost, $config)

    # Check if reporting only, else apply settings
    if ($ReportOnly) {
        $instance.printEvalReport($data)
    } else {
        $instance.setAdvancedProperties($data)
    }
}