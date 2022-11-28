Using module "..\lib\services\log-service.psm1"
Using module "..\lib\services\vmware-service.psm1"
Using module "..\lib\utils.psm1"


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