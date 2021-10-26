function Get-Thumbprint {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter()]
        [string]
        $InstanceName
    )

    return "102C445D1F01C4C5957D5CFA53FF2D7CA80E84BB"

    $thumbprint = & "c:\program files\Octopus Deploy\Tentacle\Tentacle.exe" show-thumbprint --console --nologo --instance $InstanceName
    $thumbprint = $thumbprint -replace '==== ShowThumbprintCommand starting ====', ''
    $thumbprint = $thumbprint -replace 'The thumbprint of this Tentacle is: ', ''
    $thumbprint = $thumbprint -replace '==== ShowThumbprintCommand completed ====', ''
    $thumbprint = $thumbprint -replace '==== ShowThumbprintCommand ====', ''
    return $thumbprint.Trim()
}
