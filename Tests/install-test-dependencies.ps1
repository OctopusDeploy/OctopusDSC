
echo "##teamcity[blockOpened name='Installing gem bundle']"

# temporary until the base image has the correct version
echo "running 'C:\tools\ruby23\bin\gem.cmd install bundler --version 1.14.4 --no-ri --no-rdoc'"
& C:\tools\ruby23\bin\gem.cmd install bundler --version 1.14.4 --no-ri --no-rdoc
if ($LASTEXITCODE -ne 0) { exit 1 }

Set-Location c:\temp\tests
& C:\tools\ruby23\bin\bundle.bat _1.14.4_ install --path=vendor
if ($LASTEXITCODE -ne 0) { exit 1 }

echo "##teamcity[blockClosed name='Install gem bundle']"

