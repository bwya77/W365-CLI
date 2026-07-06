BeforeDiscovery {
    $script:PublicFunctions = @(
        'Invoke-W365CLI',
        'Invoke-W365Resize',
        'Show-W365CloudApp',
        'Show-W365CloudPC',
        'Show-W365ConnectivityHistory',
        'Show-W365CustomImage',
        'Show-W365DiskSpace',
        'Show-W365GalleryImage',
        'Show-W365LaunchDetail',
        'Show-W365LicensingAllotment',
        'Show-W365MaintenanceWindow',
        'Show-W365OrganizationSetting',
        'Show-W365ProvisioningPolicy',
        'Show-W365Report',
        'Show-W365ServicePlan',
        'Show-W365SettingProfile',
        'Show-W365Snapshot',
        'Show-W365SupportedRegion',
        'Show-W365UserSetting',
        'Show-W365Usage'
    )

    $script:PublicAliases = @(
        'w365'
    )
}

Describe 'W365CLI module' {
    BeforeAll {
        $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
        $script:ManifestPath = Join-Path $ModuleRoot 'W365CLI.psd1'
        Get-Module W365CLI | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module $ManifestPath -Force -ErrorAction Stop
        $script:Manifest = Test-ModuleManifest -Path $ManifestPath
    }

    AfterAll {
        Get-Module W365CLI | Remove-Module -Force -ErrorAction SilentlyContinue
    }

    Context 'Manifest' {
        It 'has a valid manifest' {
            $Manifest | Should -Not -BeNullOrEmpty
        }

        It 'targets PowerShell 7+' {
            $Manifest.PowerShellVersion | Should -BeGreaterOrEqual ([version]'7.0')
        }
    }

    Context 'Exports' {
        It 'exports exactly the expected public functions' {
            $exported = (Get-Command -Module W365CLI -CommandType Function | Sort-Object Name).Name
            $expected = $PublicFunctions | Sort-Object
            $exported | Should -Be $expected
        }

        It 'exports exactly the expected aliases' {
            $exported = (Get-Command -Module W365CLI -CommandType Alias | Sort-Object Name).Name
            $expected = $PublicAliases | Sort-Object
            $exported | Should -Be $expected
        }

        It 'maps w365 to Invoke-W365CLI' {
            $alias = Get-Alias -Name w365 -ErrorAction Stop
            $alias.Definition | Should -Be 'Invoke-W365CLI'
        }
    }

    Context 'Formatting' {
        It 'formats fixed-width text without splitting it into characters' {
            InModuleScope W365CLI {
                $result = Format-W365CliText -Text 'Cloud PC Enterprise 4vCPU/16GB/256GB' -Width 20
                $result | Should -BeOfType ([string])
                $result.Length | Should -Be 20
                $result | Should -BeLike 'Cloud PC Enterpri...'
            }
        }
    }
}
