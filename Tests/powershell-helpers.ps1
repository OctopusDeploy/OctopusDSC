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
    write-host "Please set the $variableName environment variable" -foregroundcolor red
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
    write-host "Please install $($moduleName): Install-Module -Name $moduleName -Force" -foregroundcolor red
    exit 1
  }
}

function Test-CustomVersionOfVagrantDscPluginIsInstalled() {
  $path = Resolve-Path ~/.vagrant.d/gems/*/gems/vagrant-dsc-*/lib/vagrant-dsc/provisioner.rb

  if (Test-Path $path) {
    $content = Get-Content $path -raw
    if ($content.IndexOf("return version.stdout") -gt -1) {
      return;
    }
  }

  write-host "It doesn't appear that you've got the custom Octopous version of the vagrant-dsc plugin installed" -foregroundcolor red
  write-host "Please download it from github:"
  write-host "  irm https://github.com/OctopusDeploy/vagrant-dsc/releases/download/v2.0.1/vagrant-dsc-2.0.1.gem -outfile vagrant-dsc-2.0.1.gem"
  write-host "  vagrant plugin install vagrant-dsc-2.0.1.gem"
  exit 1
}
