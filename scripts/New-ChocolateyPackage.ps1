<#
.SYNOPSIS
Renders the nuspec and install scripts for a released Windows installer and runs `choco pack`; returns the .nupkg path.
#>
param(
    [Parameter(Mandatory)][string]$Version,
    [Parameter(Mandatory)][string]$Id,
    [Parameter(Mandatory)][string]$ProductName,
    [Parameter(Mandatory)][string]$InstallerPath,
    [Parameter(Mandatory)][string]$BaseUrl,
    [Parameter(Mandatory)][string]$OutputFolder,
    [string]$LicenseUrl = 'https://api.intentarchitect.com/redirect/TPp2sM9k',
    [string]$CopyrightHolder = 'Intent Architect Holdings Ltd',
    [string]$PackageSourceUrl = 'https://github.com/IntentArchitect/Intent.IntentArchitect.Chocolatey'
)

$installerName = Split-Path $InstallerPath -Leaf
$sha256 = (Get-FileHash -Path $InstallerPath -Algorithm SHA256).Hash.ToLowerInvariant()
$url = "$($BaseUrl.TrimEnd('/'))/$([uri]::EscapeDataString($installerName))"
$escapedProductName = [System.Security.SecurityElement]::Escape($ProductName)  # matches the installed app's display name, for the uninstaller lookup
$copyright = "Copyright (c) $((Get-Date).Year) $([System.Security.SecurityElement]::Escape($CopyrightHolder))"
$semVer = [System.Management.Automation.SemanticVersion]::Parse($Version)
$releaseNotesUrl = "https://docs.intentarchitect.com/release-notes/intent-architect-v$($semVer.Major).$($semVer.Minor).html#version-$($semVer.Major)$($semVer.Minor)$($semVer.Patch)"

$nuspec = @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>$Id</id>
    <version>$Version</version>
    <title>Intent Architect</title>
    <authors>Intent Architect</authors>
    <owners>Intent Architect</owners>
    <projectUrl>https://intentarchitect.com/</projectUrl>
    <packageSourceUrl>$PackageSourceUrl</packageSourceUrl>
    <iconUrl>https://cdn.intentarchitect.com/media/icon-light.png</iconUrl>
    <copyright>$copyright</copyright>
    <licenseUrl>$LicenseUrl</licenseUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <docsUrl>https://docs.intentarchitect.com/</docsUrl>
    <tags>intent-architect dotnet ai agentic code-generation software-architecture spec-driven-development mcp</tags>
    <summary>Control plane for agentic .NET software development: architectural guardrails, design blueprints and spec-driven traceability.</summary>
    <description>Intent Architect is the control plane for agentic .NET software development. It turns AI into a well-governed, repeatable, enterprise-scale delivery system, so teams can scale AI-driven development without losing architectural consistency.

* **Architectural guardrails**: enforce your system's architecture and patterns, with minimal code review needed.
* **Design blueprints**: model-based visual designs that stay in sync with the codebase.
* **Validation tools**: code review focuses on meaningful changes, such as design shifts and high-risk modifications.
* **Spec-driven development**: requirements are traceable to the code that realises them.
* **Bring your own AI**: works with Claude Code, GitHub Copilot, Cursor and other harnesses via the Intent MCP, with 100+ modules for .NET, Azure, databases and messaging.

**Account and licensing**: Intent Architect is a paid, subscription-only product with no free tier or trial. A licensed Intent Architect account is required, and you sign in when you first launch the app. To get access reach out to us through [our website](https://intentarchitect.com/redirect/Rbb6rPdf).

This package installs the desktop application for the current user; the app keeps itself up to date.</description>
    <releaseNotes>$releaseNotesUrl</releaseNotes>
  </metadata>
  <files>
    <file src="tools/**" target="tools" />
  </files>
</package>
"@

$install = @"
`$ErrorActionPreference = 'Stop'

Install-ChocolateyPackage ``
    -PackageName '$Id' ``
    -FileType 'exe' ``
    -SilentArgs '/S /currentuser' ``
    -Url64bit '$url' ``
    -Checksum64 '$sha256' ``
    -ChecksumType64 'sha256' ``
    -ValidExitCodes @(0)
"@

$uninstall = @"
`$ErrorActionPreference = 'Stop'

`$keys = Get-UninstallRegistryKey -SoftwareName '$escapedProductName*'
foreach (`$key in `$keys) {
    `$uninstaller = (`$key.UninstallString -replace '^"?([^"]+)"?.*`$', '`$1')
    Uninstall-ChocolateyPackage ``
        -PackageName '$Id' ``
        -FileType 'exe' ``
        -SilentArgs '/S /currentuser' ``
        -File `$uninstaller ``
        -ValidExitCodes @(0)
}
"@

$packageFolder = Join-Path $OutputFolder $Id
$toolsFolder = Join-Path $packageFolder 'tools'
New-Item -ItemType Directory -Force -Path $toolsFolder | Out-Null
Set-Content -Path (Join-Path $packageFolder "$Id.nuspec") -Value $nuspec -Encoding utf8NoBOM
Set-Content -Path (Join-Path $toolsFolder 'chocolateyInstall.ps1') -Value $install -Encoding utf8NoBOM
Set-Content -Path (Join-Path $toolsFolder 'chocolateyUninstall.ps1') -Value $uninstall -Encoding utf8NoBOM

& (Join-Path $PSScriptRoot 'Invoke-Choco.ps1') -WorkingDirectory $packageFolder pack | Write-Host

$nupkg = Join-Path $packageFolder "$Id.$Version.nupkg"
Write-Host "Installer URL: $url"
Write-Host "SHA256: $sha256"
Write-Host "Wrote $nupkg"
return $nupkg
