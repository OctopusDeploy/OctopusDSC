
echo "##teamcity[blockOpened name='Installing gem bundle']"

Set-Location c:\temp\tests
& C:\tools\ruby23\bin\bundle.bat install --path=vendor
if ($LASTEXITCODE -ne 0) { exit 1 }

echo "##teamcity[blockClosed name='Install gem bundle']"

