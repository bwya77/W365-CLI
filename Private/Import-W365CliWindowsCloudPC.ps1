function Import-W365CliWindowsCloudPC {
    [CmdletBinding()]
    param(
        [string]$ModulePath
    )

    begin { }

    process {
        if (Get-Module -Name WindowsCloudPC) {
            return
        }

        if ($ModulePath) {
            Import-Module $ModulePath -Force -ErrorAction Stop
            return
        }

        $moduleRoot = Split-Path -Path $PSScriptRoot -Parent
        $repoRoot = Split-Path -Path $moduleRoot -Parent
        $siblingManifest = Join-Path -Path $repoRoot -ChildPath 'WindowsCloudPC\WindowsCloudPC.psd1'

        if (Test-Path -Path $siblingManifest) {
            Import-Module $siblingManifest -Force -ErrorAction Stop
            return
        }

        Import-Module WindowsCloudPC -ErrorAction Stop
    }

    end { }
}
