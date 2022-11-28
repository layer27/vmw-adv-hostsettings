class VmwareConnection {

  [object] $vcenter

  VmwareConnection([string]$vCenterName, [pscredential]$credential) {
    try {
      $this.vcenter = Connect-VIServer -Server $vCenterName -Credential $credential
    } catch {
      throw "Error connecting to vCenter $($vCenterName): $($_.Exception.Message)"
    }
  }

  [object] getAdvancedPropertyValue([string] $hostName, [string] $propertyName) {
    try {
      $vmHost = Get-VmHost -Name $hostName -Server $this.vcenter
      $setting = Get-AdvancedSetting -Entity $vmHost -Server $this.vcenter -Name $propertyName
      return $setting.Value
    } catch {
      throw "Error getting advanced property [$propertyName] on host [$hostName]: $($_.Exception.Message)"
    }
  }

  [void] setAdvancedPropertyValue([string] $hostName, [string] $propertyName, [object] $value) {
    try {
      $vmHost = Get-VmHost -Name $hostName -Server $this.vcenter
      $setting = Get-AdvancedSetting -Entity $vmHost -Server $this.vcenter -Name $propertyName
      Set-AdvancedSetting -AdvancedSetting $setting -Value $value -Confirm:$false 2> $null
    } catch {
      throw "Error setting advanced property [$propertyName] on host [$hostName]: $($_.Exception.Message)"
    }
  }

  [bool] compareAdvancedPropertyValue ([string]$hostName, [string]$propertyName, [object]$value) {
    try {
      $currentValue = $this.getAdvancedPropertyValue($hostName, $propertyName)
      return ($currentValue -eq $value)
    } catch {
      throw "Error comparing advanced property [$propertyName] on host [$hostName]: $($_.Exception.Message)"
    }
  }
}