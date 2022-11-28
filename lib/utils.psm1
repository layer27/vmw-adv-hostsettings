class Utils {

  static [object] convertToHashtable ([object]$data) {
    try {
      if ($null -eq $data) {
        return $null
      } else {
        if ($data -is [System.Collections.IEnumerable] -and $data -isnot [string]) {
          $collection = @(
            foreach ($item in $data) {
              [Utils]::convertToHashtable($item)
            }
          )
          return $collection
        } elseif ($data -is [PsObject]) {
          $hash = @{}
          foreach ($prop in $data.PsObject.Properties) {
            $hash[$prop.Name] = [Utils]::convertToHashtable($prop.Value)
          }
          return $hash
        } else {
          return $data
        }
      }
      
    } catch  {
      throw "Error converting data to hashtable: $($_.Exception.Message)"
    }
  }

  static [object] convertHashtableToDotNotation ([object] $data) {
    try {
      $strings = @()
      if ($data -is [hashtable]) {
        foreach ($key in $data.keys) {
          if ($data.$key -is [hashtable]) {
            $vals = [Utils]::convertHashtableToDotNotation($data.$key)
            if ($vals -is [array]) {
              foreach ($str in $vals) {
                if ($null -ne $str) {
                  $strings += "$key.$str"
                } else {
                  $strings += "$key"
                }
              }
            } else {
              if ($null -ne $vals) {
                $strings += "$key.$vals"
              } else {
                $strings += "$key"
              }
            }
          } else {
            $strings += "$key"
          } 
        }

      } else {
        $strings += $data
      }
      return $strings
    } catch {
      throw "Error converting hashtable to dot notation: $($_.Exception.Message)"
    }
  }

  static [object] fetchValueByDotNotation ([object] $data, [string] $path) {
    $pSteps = $path.Split(".")
    $val = $data
    foreach ($step in $pSteps) {
      $val = $val.$step
    }

    return $val
  }

}