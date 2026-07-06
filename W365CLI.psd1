@{
    RootModule        = 'W365CLI.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '3a4ad504-41ef-4a27-a347-47d9f61b7ef1'
    Author            = 'Bradley Wyatt'
    CompanyName       = 'Windows From Anywhere'
    Copyright         = '(c) Bradley Wyatt. All rights reserved.'
    Description       = 'Interactive CLI for Windows 365 Cloud PC workflows built on the WindowsCloudPC PowerShell module.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
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
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @(
        'w365'
    )
    PrivateData       = @{
        PSData = @{
            Tags       = @('Windows365','CloudPC','W365','CLI','MicrosoftGraph')
            ProjectUri = ''
            LicenseUri = ''
        }
    }
}
