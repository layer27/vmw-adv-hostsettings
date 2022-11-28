class LogService {

    # used for singleton instance
    static [LogService] $_instance

    [string] $name = "VMW-ADV-HOSTSETTINGS"
    [string] $logPath
    [string] $logFile
    [string] $errLogFile
    [string] $debugLogFile
    [bool] $debugEnabled = $false

    # Headers Written
    [bool] $logHeaderWritten = $false
    [bool] $errLogHeaderWritten = $false
    [bool] $debugLogHeaderWritten = $false

    LogService () {
        $this.logPath = (Get-Location).Path
        $ts = $(Get-Date).ToString("yyyy-MM-dd")
        $this.logFile = "$($this.logPath)\log_$ts.log"
        $this.errLogFile = "$($this.logPath)\err-log_$ts.log"
        $this.debugLogFile = "$($this.logPath)\debug-log_$ts.log"
        $this.ensurePath()

        if (($Script:EnableDebug -eq $true) -or ($Global:EnableDebug -eq $true)) {
            $this.debugEnabled = $true
        }
    }

    LogService ([string] $path) {
        $this.logPath = $path
        $ts = $(Get-Date).ToString("yyyy-MM-dd")
        $this.logFile = "$($this.logPath)\log_$ts.log"
        $this.errLogFile = "$($this.logPath)\err-log_$ts.log"
        $this.debugLogFile = "$($this.logPath)\debug-log_$ts.log"
        $this.ensurePath()

        if (($Script:EnableDebug -eq $true) -or ($Global:EnableDebug -eq $true)) {
            $this.debugEnabled = $true
        }
    }

    LogService ([string] $path, [string] $logName) {
        $this.logPath = $path
        $this.name = $logName
        $ts = $(Get-Date).ToString("yyyy-MM-dd")
        $this.logFile = "$($this.logPath)\log_$ts.log"
        $this.errLogFile = "$($this.logPath)\err-log_$ts.log"
        $this.debugLogFile = "$($this.logPath)\debug-log_$ts.log"
        $this.ensurePath()

        if (($Script:EnableDebug -eq $true) -or ($Global:EnableDebug -eq $true)) {
            $this.debugEnabled = $true
        }
    }

    static [LogService] service () {
        if ($null -eq [LogService]::_instance) {
            [LogService]::_instance = [LogService]::new()
        }
        return [LogService]::_instance
    }

    static [LogService] service ([string] $path) {
        if ($null -eq [LogService]::_instance) {
            [LogService]::_instance = [LogService]::new($path)
        }
        return [LogService]::_instance
    }

    static [LogService] service ([string] $path, [string] $logName) {
        if ($null -eq [LogService]::_instance) {
            [LogService]::_instance = [LogService]::new($path, $logName)
        }
        return [LogService]::_instance
    }

    ensurePath () {
        try {
            if (!(Test-Path -path $this.logPath)) { 
                New-Item -path $this.logPath -ItemType Directory 
            }
        } catch {
            Write-Host "[ ERROR ] Unable to create log directory at path: $($this.logPath). Message: $($_.Exception.Message)" -ForegroundColor Red
            break
        }
        
    }

    newLogHeader () {
        try {
            # set log header written flag
            $this.logHeaderWritten = $true
            
            $logName = $this.name.ToUpper()
            $ts = $(Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
            $start = "`n`n"
            $header = "~~~========    $logName LOG FILE - RUN: $ts   ========~~~"
            $end = "`n"

            $blurb = $start + $header + $end

            # write to files
            $blurb | Out-File -FilePath $this.logFile -Append 2>$null

            

        } catch {
            Write-Host "[ ERROR ] Unable to write new log header. Message: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    newErrorLogHeader () {
        try {
            # set log header written flag
            $this.errLogHeaderWritten = $true

            $logName = $this.name.ToUpper()
            $ts = $(Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
            $start = "`n`n"
            $header = "~~~========    $logName ERROR LOG FILE - RUN: $ts   ========~~~"
            $end = "`n"

            $blurb = $start + $header + $end

            # write to files
            $blurb | Out-File -FilePath $this.errLogFile -Append 2>$null

        } catch {
            Write-Host "[ ERROR ] Unable to write new error log header. Message: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    newDebugLogHeader () {
        try {
            # set log header written flag
            $this.debugLogHeaderWritten = $true

            $logName = $this.name.ToUpper()
            $ts = $(Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
            $start = "`n`n"
            $header = "~~~========    $logName DEBUG LOG FILE - RUN: $ts   ========~~~"
            $end = "`n"

            $blurb = $start + $header + $end

            # write to files
            $blurb | Out-File -FilePath $this.debugLogFile -Append 2>$null

        } catch {
            Write-Host "[ ERROR ] Unable to write new debug log header. Message: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    log ([string] $message) {
        $this._log($message,"info")
    }

    log ([string] $message, [string] $level) {
        $this._log($message,$level)
    }

    debug ([string] $message) {
        $this._log($message, "debug")
    }

    error ([string] $message) {
        $this._log($message,"error")
    }

    error ([string] $message, [object] $exception) {
        $this._log($message,"error")
        $this._error($exception)
    }

    _log ([string] $message, [string] $level) {
        try {

            # readable timestamp
            $ts = $(Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
            $levelCaps = $level.ToUpper()
            # prefix
            $prefix = "[ $levelCaps ] $ts :"
            $line = "$prefix $message"

            if ($level -ne "debug") {
                # Append to Log File
                if (!$this.logHeaderWritten) {
                    $this.newLogHeader()
                }
                $line | Out-File -FilePath $this.logFile -Append 2>$null
            }

            if ($this.debugEnabled) {
                # Append to Debug Log File
                if (!$this.debugLogHeaderWritten) {
                    $this.newDebugLogHeader()
                }
                $line | Out-File -FilePath $this.debugLogFile -Append 2>$null
            }

        } catch {
            Write-Host "[ ERROR ] Unable to write log message. Message: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    _error ([object] $exception) {
        try {
            $pad1 = "     "
            $pad2 = "                 "

            # Error Log Vars
            $myComm = "$pad1 MyCommand: $($exception.InvocationInfo.MyCommand)"
            $scriptName = "$pad1 ScriptName: $($exception.InvocationInfo.ScriptName)"
            $scriptLine = "$pad1 ScriptLine: $($exception.InvocationInfo.ScriptLineNumber)"
            $scriptRoot = "$pad1 ScriptRoot: $($exception.InvocationInfo.PSScriptRoot)"
            $invocationName = "$pad1 InvocationName: $($exception.Invocation.InvocationName)"
            $errMsg = "$pad1 Message: $($exception.Exception.Message)"

            # Break Long Message Into Multiple Lines
            $lines = $exception.ScriptStackTrace -split "`n"

            if (!$this.errLogHeaderWritten) {
                $this.newErrorLogHeader()
            }

            # write to files
            $myComm | Out-File -FilePath $this.errLogFile -Append 2>$null
            $scriptName | Out-File -FilePath $this.errLogFile -Append 2>$null
            $scriptLine | Out-File -FilePath $this.errLogFile -Append 2>$null
            $scriptRoot | Out-File -FilePath $this.errLogFile -Append 2>$null
            $invocationName | Out-File -FilePath $this.errLogFile -Append 2>$null
            $errMsg | Out-File -FilePath $this.errLogFile -Append 2>$null

            # write message
            $line1 = $true
            $trace = @()
            foreach($l in $lines) {
                if ($line1) {
                    $trace += "$pad1 StackTrace: $l"
                    $line1 = $false
                } else {
                    $trace += $pad2 + $l
                }
            }
            $trace -join "`n" | Out-File -FilePath $this.errLogFile -Append 2>$null

            if ($this.debugEnabled) {
                # Append to Debug Log File
                if (!$this.debugLogHeaderWritten) {
                    $this.newDebugLogHeader()
                }

                $myComm | Out-File -FilePath $this.debugLogFile -Append 2>$null
                $scriptName | Out-File -FilePath $this.debugLogFile -Append 2>$null
                $scriptLine | Out-File -FilePath $this.debugLogFile -Append 2>$null
                $scriptRoot | Out-File -FilePath $this.debugLogFile -Append 2>$null
                $invocationName | Out-File -FilePath $this.debugLogFile -Append 2>$null
                $errMsg | Out-File -FilePath $this.debugLogFile -Append 2>$null
                $trace -join "`n" | Out-File -FilePath $this.debugLogFile -Append 2>$null
            }
        } catch {
            Write-Host "[ ERROR ] Unable to write error log message. Message: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

}