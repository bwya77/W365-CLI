#Requires -Version 7.0
<#
.SYNOPSIS
    Build, test, and publish helper for W365CLI.

.PARAMETER Task
    Task to run: Test, Build, Publish, or All.

.PARAMETER ApiKey
    PowerShell Gallery API key. Defaults to PSGALLERY_API_KEY.

.PARAMETER OutputPath
    Staging path for the built module.
#>
[CmdletBinding()]
param(
    [ValidateSet('Test','Build','Publish','All')]
    [string]$Task = 'All',

    [string]$ApiKey = $env:PSGALLERY_API_KEY,

    [string]$OutputPath = (Join-Path $PSScriptRoot 'Output\W365CLI')
)

$ErrorActionPreference = 'Stop'
$ModuleRoot = $PSScriptRoot

function Install-RequiredModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$MinimumVersion
    )

    $existing = Get-Module -ListAvailable -Name $Name
    if ($MinimumVersion) {
        $existing = $existing | Where-Object { $_.Version -ge [version]$MinimumVersion }
    }

    if (-not $existing) {
        $installParams = @{
            Name               = $Name
            Scope              = 'CurrentUser'
            Force              = $true
            SkipPublisherCheck = $true
            AllowClobber       = $true
        }
        if ($MinimumVersion) {
            $installParams.MinimumVersion = $MinimumVersion
        }

        Install-Module @installParams
    }
}

function Invoke-TestTask {
    [CmdletBinding()]
    param()

    Install-RequiredModule -Name Pester -MinimumVersion 5.5.0
    Install-RequiredModule -Name PSScriptAnalyzer -MinimumVersion 1.21.0
    Install-RequiredModule -Name WindowsCloudPC -MinimumVersion 0.1.24

    Import-Module PSScriptAnalyzer -ErrorAction Stop
    $analysisPaths = @(
        Join-Path $ModuleRoot 'W365CLI.psm1'
        Join-Path $ModuleRoot 'W365CLI.psd1'
        Join-Path $ModuleRoot 'w365.ps1'
        Join-Path $ModuleRoot 'Public'
        Join-Path $ModuleRoot 'Private'
    )

    $issues = foreach ($path in $analysisPaths) {
        if (Test-Path -Path $path) {
            Invoke-ScriptAnalyzer -Path $path -Recurse -Settings PSGallery
        }
    }

    if ($issues) {
        $issues | Format-Table -AutoSize | Out-Host
        $blocking = $issues | Where-Object Severity -in 'Error','Warning'
        if ($blocking) {
            throw "$($blocking.Count) blocking lint issue(s)."
        }
    }

    Invoke-Pester -Path (Join-Path $ModuleRoot 'Tests') -Output Detailed
}

function Invoke-BuildTask {
    [CmdletBinding()]
    param()

    if (Test-Path -Path $OutputPath) {
        Remove-Item -Path $OutputPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

    $items = @(
        'W365CLI.psd1'
        'W365CLI.psm1'
        'Public'
        'Private'
        'README.md'
        'LICENSE'
    )

    foreach ($item in $items) {
        $source = Join-Path $ModuleRoot $item
        if (Test-Path -Path $source) {
            Copy-Item -Path $source -Destination $OutputPath -Recurse -Force
        }
    }

    Test-ModuleManifest -Path (Join-Path $OutputPath 'W365CLI.psd1') | Out-Null
    Write-Host "Staged W365CLI at $OutputPath" -ForegroundColor Green
}

function Invoke-PublishTask {
    [CmdletBinding()]
    param()

    if (-not $ApiKey) {
        throw 'ApiKey or PSGALLERY_API_KEY is required for Publish.'
    }

    if (-not (Test-Path -Path $OutputPath)) {
        Invoke-BuildTask
    }

    Publish-Module -Path $OutputPath -NuGetApiKey $ApiKey -Verbose -ErrorAction Stop
}

switch ($Task) {
    'Test' {
        Invoke-TestTask
    }
    'Build' {
        Invoke-BuildTask
    }
    'Publish' {
        Invoke-TestTask
        Invoke-BuildTask
        Invoke-PublishTask
    }
    'All' {
        Invoke-TestTask
        Invoke-BuildTask
    }
}
