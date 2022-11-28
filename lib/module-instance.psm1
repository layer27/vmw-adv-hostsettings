Using module "..\lib\services\log-service.psm1"
Using module "..\lib\services\vmware-service.psm1"
Using module ".\utils.psm1"


class ModuleInstance {

  [LogService] $logService
  [VmwareService] $vmwareService

  [string] $logsFolder

  [bool] $enableDebugging = $false

  ModuleInstance () {

    if (($Script:EnableDebug -eq $true) -or ($Global:EnableDebug -eq $true)) {
      $this.enableDebugging = $true
    }

    # Configure Logging
    $location = (Get-Location).Path
    $this.logsFolder = "$($location)\logs"
    $this.logService = [LogService]::new($this.logsFolder)
    if ($this.enableDebugging) {
      $this.logService.debugEnabled = $true
    }

    $this.debug("Logging Path configured: $($this.logsFolder)")
  }


  connectVcenter([string]$vCenter) {
    $this.debug("Connecting to vCenter: $vCenter")
    try {
      $credential = Get-Credential -Message "Enter Credentials for vCenter: $vCenter"
      $this.vmwareService = [VmwareService]::new($vCenter, $credential)
      $this.log("Successfully Connected to vCenter: $vCenter")
    } catch {
      $this.error("Error Connecting to vCenter: $vCenter", $_)
    }
  }

  connectVcenter([string]$vCenter, [PSCredential] $credential) {
    $this.debug("Connecting to vCenter: $vCenter")
    try {
      $this.vmwareService = [VmwareService]::new($vCenter, $credential)
      $this.log("Successfully Connected to vCenter: $vCenter")
    } catch {
      $this.error("Error Connecting to vCenter: $vCenter", $_)
    }
  }

  setHostProperty([string] $hostName, [string] $propertyName, [object] $value) {
    $this.debug("Setting property $propertyName to $value on host: $hostName")
    try {
      $this.vmwareService.setAdvancedPropertyValue($hostName, $propertyName, $value)
      $this.log("Set property $propertyName to $value on host: $hostName")
    } catch {
      $this.error("Error setting property $propertyName to $value on host: $hostName", $_)
    }
  }

  [object] evalHostProperties([string] $hostname, [object] $reference) {
    try {
      
      # convert data to hashtable
      $hash = [Utils]::convertToHashtable($reference)
      # get dot notation for properties
      $properties = [Utils]::convertHashtableToDotNotation($hash)


      $results = @{
        hostname=$hostname;
        properties=$();
      }

      foreach($prop in $properties) {
        $targetVal = [Utils]::fetchValueByDotNotation($hash, $prop)
        $currentVal = $this.vmwareService.getAdvancedPropertyValue($hostname, $prop)

        $result = @{
          updateRequired=($targetVal -ne $currentVal);
          currentValue=$currentVal;
          targetValue=$targetVal;
          property=$prop;
          hostname=$hostname;
        }

        $results.properties += $result
      }

      return $results

    } catch {
      $this.error("Error evaluating advanced properties on host [$hostname].", $_)
      return $null
    }
    
  }

  printEvalReport ([object] $data) {
    $this.debug("Printing Advanced Properties Evalutation Report")
    try {
      if ($null -ne $data) {
        $hostname = $data.hostname
        
        # Generate Report Output
        Write-Host "`n=========== HOST: $hostname Advanced Properties Report ===========`n" -ForegroundColor Cyan
        
        foreach ($line in $data.properties) {
          $this.debug("Property: $($line.property) | Update Required?: $($line.updateRequired) | Current Value: $($line.currentValue) | Target Value: $($line.targetValue)")
          if ($line.updateRequired) {
            Write-Host "  Property: $($line.property) | Update Required?: TRUE | Current Value: $($line.currentValue) | Target Value: $($line.targetValue)" -ForegroundColor Yellow
          } else {
            Write-Host "  Property: $($line.property) | Update Required?: FALSE" -ForegroundColor Green
          }
        }

        Write-Host "`n==================================================================`n" -ForegroundColor Cyan

      } else {
        $this.log("Advanced Properties Evaluation Dataset is Empty.")
      }
    } catch {
      $this.error("Error printing advanced properties evaluation report.", $_)
    }
  }

  setAdvancedProperties([object] $data) {
    $this.debug("Setting Advanced Properties from Evaluation Data")
    try {
      if ($null -ne $data) {
        $hostname = $data.hostname
        foreach ($item in $data.properties) {
          if ($item.updateRequired) {
            $this.debug("Property '$($item.property)' on host $($hostname) requires update. Current value: $($item.currentValue); Target Value: $($item.targetValue).")
            try {
              $this.vmwareService.setAdvancedPropertyValue($hostname, $item.property, $item.targetValue)
              $this.log("Property '$($item.property)' on host $($hostname) has been set to value: $($item.targetValue)")
            } catch {
              $this.error("Error setting Property '$($item.property)' on host $($hostname) to value: $($item.targetValue).", $_)
            }
          } else {
            $this.debug("Property '$($item.property)' on host $($hostname) does not require update. Current value: $($item.currentValue); Target Value: $($item.targetValue).")
          }
        }
      } else {
        $this.log("No Advanced Properties to Set. Dataset is Empty.")
      }
    } catch {
      $hostname = "null"
      if ($null -ne $data) {
        $hostname = $data.hostname
      }
      $this.error("Error setting advanced properties for host: $($hostname).", $_)
    }
  }

  readConfigFile([string] $path) {
    
  }


  log([string] $message) {
    $this.logService.log($message)
  }


  debug([string] $message) {
      if ($this.enableDebugging) {
          $this.logService.debug($message)
      }
  }

  error([string] $message, [object] $err) {
      $this.logService.error($message, $err)
  }
}