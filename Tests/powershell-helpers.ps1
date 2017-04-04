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
  & which $appName | Out-Null
  return $LASTEXITCODE -eq 0
}
