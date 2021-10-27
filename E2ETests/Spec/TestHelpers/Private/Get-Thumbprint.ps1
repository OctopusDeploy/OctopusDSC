function Get-Thumbprint {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter()]
        [string]
        $InstanceName
    )

    $thumbprint = & "c:\program files\Octopus Deploy\Tentacle\Tentacle.exe" show-thumbprint --console --nologo --instance $InstanceName
    $thumbprint = $thumbprint -replace '==== ShowThumbprintCommand starting ====', ''
    $thumbprint = $thumbprint -replace 'The thumbprint of this Tentacle is: ', ''
    $thumbprint = $thumbprint -replace '==== ShowThumbprintCommand completed ====', ''
    $thumbprint = $thumbprint -replace '==== ShowThumbprintCommand ====', ''
    return $thumbprint.Trim()
}
