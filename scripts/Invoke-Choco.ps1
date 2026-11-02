<#
.SYNOPSIS
Runs choco with the given arguments, through Chocolatey's Linux container image when choco isn't installed (e.g. on Linux agents).
.PARAMETER WorkingDirectory
Folder mounted into the container when it is used; every path argument must live under it.
#>
param(
    [Parameter(Mandatory)][string]$WorkingDirectory,
    [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Arguments
)

if (Get-Command choco -ErrorAction SilentlyContinue) {
    Push-Location $WorkingDirectory
    try { & choco @Arguments }
    finally { Pop-Location }
}
else {
    $mounted = (Resolve-Path $WorkingDirectory).Path
    # @() keeps a single argument an array; a lone string would be splatted as characters ('pack' -> 'p','a','c','k').
    $mappedArguments = @($Arguments | ForEach-Object { $_.Replace($mounted, '/work') })
    docker run --rm -v "${mounted}:/work" -w /work chocolatey/choco:latest-linux choco @mappedArguments
}
if ($LASTEXITCODE -ne 0) { throw "choco $($Arguments[0]) failed" }
