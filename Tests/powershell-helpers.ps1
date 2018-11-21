function Test-PluginInstalled($pluginName, $pluginVersion) {

  $result = (& vagrant plugin list)
  if ($null -eq $pluginVersion) {
    if ($result -like "*$pluginName *") {
      write-host "Vagrant plugin $pluginName exists - good."
    }
    else {
      write-host "Vagrant plugin $pluginName not installed."
      & vagrant plugin install $pluginName
    }
  }
  else {
    if ($result -like "*$pluginName ($pluginVersion)*") {
      write-host "Vagrant plugin $pluginName v$pluginVersion exists - good."
    }
    else {
      write-host "Vagrant plugin $pluginName v$pluginVersion not installed."
      & vagrant plugin install $pluginName --plugin-version "$pluginVersion"
    }
  }
}

function Test-EnvVar($variableName) {
  if (-not (Test-Path env:$variableName)) {
    write-host "Please set the $variableName environment variable"
    exit 1
  }
}

function Test-AppExists($appName) {
  $command = Get-Command $appName -ErrorAction SilentlyContinue
  return $null -ne $command
}

function Test-PowershellModuleInstalled($moduleName) {
  $command = Get-Module $moduleName -listavailable
  if ($null -eq $command) {
    write-host "Please install $($moduleName): Install-Module -Name $moduleName -Force"
    exit 1
  }
}
