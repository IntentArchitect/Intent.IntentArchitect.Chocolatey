# Intent Architect Chocolatey package

Packaging source for the [`intent-architect`](https://community.chocolatey.org/packages/intent-architect) Chocolatey package. Intent Architect itself is closed-source commercial software; this repo only builds the package that downloads and silently installs the signed installer.

`scripts/New-ChocolateyPackage.ps1` renders the nuspec and install/uninstall scripts for a release and runs `choco pack`. `scripts/Invoke-Choco.ps1` runs `choco`, or Chocolatey's Linux container image where it isn't installed.

The package is built and pushed by the Intent Architect client release pipeline for stable releases; there is nothing to run by hand.
