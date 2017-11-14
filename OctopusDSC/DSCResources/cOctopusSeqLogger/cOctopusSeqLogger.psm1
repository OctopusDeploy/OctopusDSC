$octopusServerExePath = "$($env:ProgramFiles)\Octopus Deploy\Octopus\Octopus.Server.exe"
$tentacleExePath = "$($env:ProgramFiles)\Octopus Deploy\Tentacle\Tentacle.exe"

function Get-TargetResource {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
  [OutputType([HashTable])]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("OctopusServer", "Tentacle")]
    [string]$InstanceType,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Present", "Absent")]
    [string]$Ensure,
    [string]$SeqServer,
    [PSCredential]$SeqApiKey,
    [Microsoft.Management.Infrastructure.CimInstance[]]$Properties
  )

  $propertiesAsHashTable = ToHashTable $properties
  return Get-TargetResourceInternal -InstanceType $InstanceType `
                                    -Ensure $Ensure `
                                    -SeqServer $SeqServer `
                                    -SeqApiKey $SeqApiKey `
                                    -Properties $propertiesAsHashTable
}

function Set-TargetResource {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("OctopusServer", "Tentacle")]
    [string]$InstanceType,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Present", "Absent")]
    [string]$Ensure,
    [string]$SeqServer,
    [PSCredential]$SeqApiKey,
    [Microsoft.Management.Infrastructure.CimInstance[]]$Properties
  )
  $propertiesAsHashTable = ToHashTable $properties
  Set-TargetResourceInternal -InstanceType $InstanceType `
                             -Ensure $Ensure `
                             -SeqServer $SeqServer `
                             -SeqApiKey $SeqApiKey `
                             -Properties $propertiesAsHashTable
}

function Test-TargetResource {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
  [OutputType([boolean])]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("OctopusServer", "Tentacle")]
    [string]$InstanceType,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Present", "Absent")]
    [string]$Ensure,
    [string]$SeqServer,
    [PSCredential]$SeqApiKey,
    [Microsoft.Management.Infrastructure.CimInstance[]]$Properties
  )

  $propertiesAsHashTable = ToHashTable $properties
  return Test-TargetResourceInternal -InstanceType $InstanceType `
                                     -Ensure $Ensure `
                                     -SeqServer $SeqServer `
                                     -SeqApiKey $SeqApiKey `
                                     -Properties $propertiesAsHashTable
}

function Get-TargetResourceInternal {
  [OutputType([Hashtable])]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("OctopusServer", "Tentacle")]
    [string]$InstanceType,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Present", "Absent")]
    [string]$Ensure,
    [string]$SeqServer,
    [PSCredential]$SeqApiKey,
    [HashTable]$Properties
  )

  if (-not (Test-Path -Path $octopusServerExePath) -and ($InstanceType -eq "OctopusServer") -and ($Ensure -eq "Present")) {
    throw "Unable to find Octopus (checked for existence of file '$octopusServerExePath')."
  }
  if (-not (Test-Path -Path $tentacleExePath) -and ($InstanceType -eq "Tentacle") -and ($Ensure -eq "Present")) {
    throw "Unable to find Tentacle (checked for existence of file '$tentacleExePath')."
  }

  if ($InstanceType -eq "Tentacle") {
    $nlogConfigFile = "$tentacleExePath.nlog"
  } elseif ($InstanceType -eq "OctopusServer") {
    $nlogConfigFile = "$octopusServerExePath.nlog"
  }

  $existingApiKey = $null
  $nlogExtensionElementExists = $false
  $nlogTargetElementExists = $false
  $nlogRuleElementExists = $false
  $existingServerUrl = $null
  $existingProperties = @{}

  if (Test-Path $nlogConfigFile) {

    $nlogConfig = Get-NLogConfig $nlogConfigFile
    $nlogExtensionElementExists = $null -ne ($nlogConfig.nlog.extensions.add.assembly | where-object { $_ -eq "Seq.Client.Nlog" })
    $nlogTargetElement = ($nlogConfig.nlog.targets.target | where-object {$_.name -eq "seq"})
    $nlogTargetElementExists = $null -ne $nlogTargetElement
    $nlogRuleElement = ($nlogConfig.nlog.rules.logger | where-object {$_.writeTo -eq "seq"})
    $nlogRuleElementExists = $null -ne $nlogRuleElement

    $plainTextPassword = ($nlogConfig.nlog.targets.target | where-object { $_.name -eq "seq" -and $_.type -eq "Seq" }).ApiKey
    if ($null -ne $plainTextPassword) {
      $password = new-object securestring
      # Avoid using "ConvertTo-SeureString ... -AsPlaintext", to fix PSAvoidUsingConvertToSecureStringWithPlainText
      # Not sure it actually solves the underlying issue though
      $plainTextPassword.ToCharArray() | Foreach-Object { $password.AppendChar($_) }
      $existingApiKey = New-Object System.Management.Automation.PSCredential ("ignored", $password)
    }
    $existingServerUrl = $nlogTargetElement.serverUrl
    if ($null -ne $nlogTargetElementExists -and ($null -ne $nlogTargetElement.property)) {
      $nlogTargetElement.property | Sort-Object -Property Name | Foreach-Object { $existingProperties[$_.name] = $_.value }
    }
  }

  if ($InstanceType -eq "Tentacle") {
    $dllPath = "$($env:ProgramFiles)\Octopus Deploy\Tentacle\Seq.Client.NLog.dll"
  } elseif ($InstanceType -eq "OctopusServer") {
    $dllPath = "$($env:ProgramFiles)\Octopus Deploy\Octopus\Seq.Client.NLog.dll"
  }

  $existingEnsure = "Absent"
  if ((Test-NLogDllExists $dllPath) -and $nlogExtensionElementExists -and $nlogTargetElementExists -and $nlogRuleElementExists) {
    $existingEnsure = "Present"
  }

  $result = @{
    InstanceType = $InstanceType;
    Ensure = $existingEnsure
    SeqServer = $existingServerUrl
    SeqApiKey = $existingApiKey
    Properties = $existingProperties
  }

  return $result
}

function Get-NLogConfig ([string] $fileName) {
  return [xml] (Get-Content $fileName)
}

function Test-NLogDllExists ([string] $fileName) {
  return Test-Path $fileName
}

function Set-TargetResourceInternal {
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("OctopusServer", "Tentacle")]
    [string]$InstanceType,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Present", "Absent")]
    [string]$Ensure,
    [string]$SeqServer,
    [PSCredential]$SeqApiKey,
    [HashTable]$Properties
  )

  Get-TargetResource -InstanceType $InstanceType `
                     -Ensure $Ensure `
                     -SeqServer $SeqServer `
                     -SeqApiKey $SeqApiKey `
                     -Properties $null

  if ($InstanceType -eq "Tentacle") {
    $dllPath = "$($env:ProgramFiles)\Octopus Deploy\Tentacle\Seq.Client.NLog.dll"
  } elseif ($InstanceType -eq "OctopusServer") {
    $dllPath = "$($env:ProgramFiles)\Octopus Deploy\Octopus\Seq.Client.NLog.dll"
  }

  if ($InstanceType -eq "Tentacle") {
    $nlogConfigFile = "$tentacleExePath.nlog"
  } elseif ($InstanceType -eq "OctopusServer") {
    $nlogConfigFile = "$octopusServerExePath.nlog"
  }

  if ($Ensure -eq "Absent") {
    if (Test-Path $dllPath) {
      # todo: do we need to stop the octopus service here?
      Remove-Item $dllPath -Force
    }
    if (Test-Path $nlogConfigFile) {
      $nlogConfig = Get-NLogConfig $nlogConfigFile

      $nlogExtensionElement = ($nlogConfig.nlog.extensions.add | where-object { $_.assembly -eq "Seq.Client.NLog" })
      if ($null -ne $nlogExtensionElement) {
        $nlogConfig.nlog.extensions.RemoveChild($nlogExtensionElement)
      }
      $nlogTargetElement = ($nlogConfig.nlog.targets.target | where-object {$_.name -eq "seq"})
      if ($null -ne $nlogTargetElement) {
        $nlogConfig.nlog.targets.RemoveChild($nlogTargetElement)
      }
      $nlogRuleElement = ($nlogConfig.nlog.rules.logger | where-object {$_.writeTo -eq "seq"})
      if ($null -ne $nlogRuleElement) {
        $nlogConfig.nlog.rules.RemoveChild($nlogRuleElement)
      }
      Save-NlogConfig $nlogConfig $nlogConfigFile
    }
  } else {
     if (-not (Test-Path $dllPath)) {
      Request-SeqClientNlogDll $dllPath
    }
    $nlogConfig = Get-NLogConfig $nlogConfigFile

    #remove then re-add "<add assembly="Seq.Client.NLog"/>" to //nlog/extensions
    $nlogExtensionElement = ($nlogConfig.nlog.extensions.add | where-object { $_.assembly -eq "Seq.Client.Nlog" })
    if ($null -ne $nlogPropertyElement) {
      $nlogConfig.nlog.extensions.RemoveChild($nlogExtensionElement)
    }
    $newChild = $nlogConfig.CreateElement("add", $nlogConfig.DocumentElement.NamespaceURI)
    $attribute = $nlogConfig.CreateAttribute("assembly")
    $attribute.Value = "Seq.Client.NLog"
    $newChild.Attributes.Append($attribute)
    $nlogConfig.nlog.extensions.AppendChild($newChild)

    #remove then re-add "
    #  <target name="seq" xsi:type="Seq" serverUrl="https://seq.octopushq.com" apiKey="wGdZV8CUL92KsGqZNVDX">
    #    <property name="tentacle-army-id" value="$tentacleArmyId" />
    #  </target>
    #to //nlog/targets"
    $nlogTargetElement = ($nlogConfig.nlog.targets.target | where-object {$_.name -eq "seq" -and $_.type -eq "Seq"})
    if ($null -ne $nlogTargetElement) {
      $nlogConfig.nlog.targets.RemoveChild($nlogTargetElement)
    }
    $newChild = $nlogConfig.CreateElement("target", $nlogConfig.DocumentElement.NamespaceURI)
    $attribute = $nlogConfig.CreateAttribute("name")
    $attribute.Value = "seq"
    $newChild.Attributes.Append($attribute)
    $attribute = $nlogConfig.CreateAttribute("xsi:type", "http://www.w3.org/2001/XMLSchema-instance")
    $attribute.Value = "Seq"
    $newChild.Attributes.Append($attribute)
    $attribute = $nlogConfig.CreateAttribute("serverUrl")
    $attribute.Value = $SeqServer
    $newChild.Attributes.Append($attribute)
    if ($null -ne $SeqApiKey) {
      $attribute = $nlogConfig.CreateAttribute("apiKey")
      $attribute.Value = $SeqApiKey.GetNetworkCredential().Password
      $newChild.Attributes.Append($attribute)
    }
    if ($null -ne $properties) {
      $sortedProperties = ($Properties.GetEnumerator() | Sort-Object -Property Key)
      foreach($property in $sortedProperties) {
        $propertyChild = $nlogConfig.CreateElement("property", $nlogConfig.DocumentElement.NamespaceURI)
        $attribute = $nlogConfig.CreateAttribute("name")
        $attribute.Value = $property.Key
        $propertyChild.Attributes.Append($attribute)
        $attribute = $nlogConfig.CreateAttribute("value")
        $attribute.Value = $property.Value
        $propertyChild.Attributes.Append($attribute)
        $newChild.AppendChild($propertyChild)
      }
    }
    $nlogConfig.nlog.targets.AppendChild($newChild)

    # remove then re-add "<logger name="*" minlevel="Info" writeTo="seq" />" to //nlog/rules"
    $nlogRuleElement = ($nlogConfig.nlog.rules.logger | where-object {$_.writeTo -eq "seq"})
    if ($null -ne $nlogRuleElement) {
      $nlogConfig.nlog.rules.RemoveChild($nlogRuleElement)
    }
    $newChild = $nlogConfig.CreateElement("logger", $nlogConfig.DocumentElement.NamespaceURI)
    $attribute = $nlogConfig.CreateAttribute("name")
    $attribute.Value = "*"
    $newChild.Attributes.Append($attribute)
    $attribute = $nlogConfig.CreateAttribute("minlevel")
    $attribute.Value = "Info"
    $newChild.Attributes.Append($attribute)
    $attribute = $nlogConfig.CreateAttribute("writeTo")
    $attribute.Value = "seq"
    $newChild.Attributes.Append($attribute)
    $nlogConfig.nlog.rules.AppendChild($newChild)

    Save-NlogConfig $nlogConfig $nlogConfigFile
  }
}

function ToHashTable {
  [CmdletBinding()]
  [OutputType([HashTable])]
  param
  (
    [Microsoft.Management.Infrastructure.CimInstance[]] $tokens
  )
  $HashTable = @{}
  foreach($token in $tokens) {
    $HashTable.Add($token.Key, $token.Value)
  }
  return $HashTable
}

function Request-SeqClientNlogDll ($dllPath) {
  $ProgressPreference = "SilentlyContinue"
  $folder = [System.IO.Path]::GetTempPath()
  Invoke-WebRequest https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -outfile "$folder\nuget.exe"
  & "$folder\nuget.exe" install Seq.Client.NLog -outputdirectory $folder -version 2.3.24
  Copy-Item "$folder\Seq.Client.NLog.2.3.24\lib\net40\Seq.Client.NLog.dll" $dllPath
}

function Save-NlogConfig ($nlogConfig, $filename) {
  $nlogConfig.Save($filename)
}

function Test-TargetResourceInternal {
  [OutputType([boolean])]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("OctopusServer", "Tentacle")]
    [string]$InstanceType,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Present", "Absent")]
    [string]$Ensure,
    [string]$SeqServer,
    [PSCredential]$SeqApiKey,
    [HashTable]$Properties
  )
  $currentResource = (Get-TargetResourceInternal -InstanceType $InstanceType `
                                                 -Ensure $Ensure `
                                                 -SeqServer $SeqServer `
                                                 -SeqApiKey $SeqApiKey `
                                                 -Properties $Properties)

  $params = Get-OctopusDSCParameter $MyInvocation.MyCommand.Parameters

  $currentConfigurationMatchesRequestedConfiguration = $true
  foreach($key in $currentResource.Keys)
  {
    $currentValue = $currentResource.Item($key)
    $requestedValue = $params.Item($key)

    if ($currentValue -is [PSCredential]) {
      if($null -ne $currentValue) {
        $currentUsername = $currentValue.GetNetworkCredential().UserName
        $currentPassword = $currentValue.GetNetworkCredential().Password
      } else {
        $currentUserName = ""
        $currentPassword = ""
      }

      if($null -ne $requestedValue) {
        $requestedUsername = $requestedValue.GetNetworkCredential().UserName
        $requestedPassword = $requestedValue.GetNetworkCredential().Password
      } else {
        $requestedUsername = ""
        $requestedPassword = ""
      }

      $requestedUsername = $requestedValue.GetNetworkCredential().UserName
      $requestedPassword = $requestedValue.GetNetworkCredential().Password

      if ($currentPassword -ne $requestedPassword -or $currentUsername -ne $requestedUserName) {
        Write-Verbose "(FOUND MISMATCH) Configuration parameter '$key' with value '********' mismatched the specified value '********'"
        $currentConfigurationMatchesRequestedConfiguration = $false
      }
      else {
        Write-Verbose "Configuration parameter '$key' matches the requested value '********'"
      }
    }
    elseif ($currentValue -is [HashTable]) {
      if ($currentValue.Count -ne $requestedValue.Count) {
        Write-Verbose "(FOUND MISMATCH) Configuration parameter '$key' with $($currentValue.count) values mismatched the specified $($requestedValue.Count) values"
        $currentConfigurationMatchesRequestedConfiguration = $false
      } else {
        foreach($value in $currentValue.Keys) {
          $curr = $currentValue[$value]
          $req = $requestedValue[$value]
          if ($curr -ne $req)
          {
            Write-Verbose "(FOUND MISMATCH) Configuration parameter `"$key['$value']`" with value '$curr' mismatched the specified value '$req'"
            $currentConfigurationMatchesRequestedConfiguration = $false
          }
        }
      }
    }
    elseif ($currentValue -ne $requestedValue)
    {
      Write-Verbose "(FOUND MISMATCH) Configuration parameter '$key' with value '$currentValue' mismatched the specified value '$requestedValue'"
      $currentConfigurationMatchesRequestedConfiguration = $false
    }
    else
    {
      Write-Verbose "Configuration parameter '$key' matches the requested value '$requestedValue'"
    }
  }

  return $currentConfigurationMatchesRequestedConfiguration
}

function Get-OctopusDSCParameter($parameters) {
  # unfortunately $PSBoundParameters doesn't contain parameters that weren't supplied (because the default value was okay)
  # credit to https://www.briantist.com/how-to/splatting-psboundparameters-default-values-optional-parameters/
  $params = @{}
  foreach($h in $parameters.GetEnumerator()) {
    $key = $h.Key
    $var = Get-Variable -Name $key -ErrorAction SilentlyContinue
    if ($null -ne $var)
    {
      $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
      $params[$key] = $val
    }
  }
  return $params
}
