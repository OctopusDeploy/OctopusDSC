echo "##teamcity[blockOpened name='Installing Chocolatey']"

if (-not (Test-Path "c:\temp\chocolatey-installed.marker")) {
  write-output "Installing Chocolatey"
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  if ($LASTEXITCODE -ne 0) { exit 1 }
  set-content "c:\temp\chocolatey-installed.marker" ""
}

echo "##teamcity[blockClosed name='Installing Chocolatey']"

echo "##teamcity[blockOpened name='Install Ruby']"

if (-not (Test-Path "c:\temp\ruby-installed.marker")) {
  choco install ruby --allow-empty-checksums --yes
  if ($LASTEXITCODE -ne 0) { exit 1 }

  refreshenv
  if ($LASTEXITCODE -ne 0) { exit 1 }

  Invoke-WebRequest "https://rubygems.org/downloads/rubygems-update-2.6.7.gem" -outFile "C:\temp\rubygems-update-2.6.7.gem"
  & C:\tools\ruby23\bin\gem.cmd install --local C:\temp\rubygems-update-2.6.7.gem
  if ($LASTEXITCODE -ne 0) { exit 1 }
  & C:\tools\ruby23\bin\update_rubygems.bat --no-ri --no-rdoc
  if ($LASTEXITCODE -ne 0) { exit 1 }
  set-content "c:\temp\ruby-installed.marker" ""
}

echo "##teamcity[blockClosed name='Install Ruby']"

echo "##teamcity[blockOpened name='Install ServerSpec']"

if (-not (Test-Path "c:\temp\serverspec-installed.marker")) {
  echo "running 'C:\tools\ruby23\bin\gem.cmd install bundler --no-ri --no-rdoc'"
  & C:\tools\ruby23\bin\gem.cmd install bundler --no-ri --no-rdoc
  if ($LASTEXITCODE -ne 0) { exit 1 }

  echo "running 'C:\tools\ruby23\bin\gem.cmd env'"
  & C:\tools\ruby23\bin\gem.cmd env
  set-content "c:\temp\serverspec-installed.marker" ""
}

echo "##teamcity[blockClosed name='Install ServerSpec']"

echo "##teamcity[blockOpened name='Installing Chocolatey']"
# need chocolatey to install git
if (-not (Test-Path "c:\temp\chocolatey-installed.marker")) {
  write-output "Installing Chocolatey"
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  if ($LASTEXITCODE -ne 0) { exit 1 }
  set-content "c:\temp\chocolatey-installed.marker" ""
}

echo "##teamcity[blockClosed name='Installing Chocolatey']"

echo "##teamcity[blockOpened name='Installing Git 2.10.1']"
# need git to install octopus-serverspec-extensions from github
if (-not (Test-Path "c:\temp\git-installed.marker")) {
  write-output "Installing git"
  choco install git --version 2.10.1 --allow-empty-checksums --yes
  if ($LASTEXITCODE -ne 0) { exit 1 }

  set-content "c:\temp\git-installed.marker" ""
}
echo "##teamcity[blockClosed name='Installing Git 2.10.1']"
