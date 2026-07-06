function Invoke-W365CLI {
    [CmdletBinding()]
    param()

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        function Connect-W365CliSession {
            param(
                [switch]$Force
            )

            if (Get-Command -Name Connect-Windows365 -ErrorAction SilentlyContinue) {
                if ($Force) {
                    Connect-Windows365 -Force | Out-Null
                }
                else {
                    Connect-Windows365 | Out-Null
                }
            }
            else {
                if ($Force) {
                    Connect-CloudPC -Force | Out-Null
                }
                else {
                    Connect-CloudPC | Out-Null
                }
            }

            $currentConnection = Get-W365CliConnection
            if ($currentConnection -and $currentConnection.Account) {
                Write-Host ("Connected as {0}" -f $currentConnection.Account) -ForegroundColor Green
            }
        }

        function Disconnect-W365CliSession {
            if (Get-Command -Name Disconnect-MgGraph -ErrorAction SilentlyContinue) {
                Disconnect-MgGraph | Out-Null
                Write-Host 'Disconnected from Microsoft Graph.' -ForegroundColor Green
            }
            else {
                Write-Warning 'Disconnect-MgGraph was not available in this session.'
            }
        }

        while ($true) {
            $connection = Get-W365CliConnection

            $menuItems = [System.Collections.Generic.List[object]]::new()
            $connectionLabel = if ($connection) { 'Connection - Reconnect or disconnect' } else { 'Connection - Connect to Windows 365' }

            $menuItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f 'Cloud PCs', 'Browse, resize, rename, disk, remote actions'); Action = 'CloudPCsArea' })
            $menuItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f 'Provisioning', 'Policies, policy copies, maintenance windows'); Action = 'ProvisioningArea' })
            $menuItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f 'Reports', 'Usage, connectivity, launch, snapshots, report streams'); Action = 'ReportsArea' })
            $menuItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f 'Cloud Apps', 'Browse, publish, and unpublish Windows 365 Cloud Apps'); Action = 'CloudAppsArea' })
            $menuItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f 'Catalog', 'Service plans and gallery images'); Action = 'CatalogArea' })
            $menuItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f 'Tenant settings', 'Organization defaults'); Action = 'TenantArea' })
            $menuItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f 'Connection', $connectionLabel.Substring(13)); Action = 'ConnectionArea' })
            $menuItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f 'Exit', 'Close W365CLI'); Action = 'Exit' })

            $choice = Read-W365CliChoice -Prompt 'Windows 365 CLI' -Choices @($menuItems.Label) -HeaderScript {
                Show-W365CliBanner -Connection $connection
                Write-Host 'Choose an area. Each area has its own focused actions.' -ForegroundColor DarkGray
            }
            $action = $menuItems[$choice].Action

            switch ($action) {
                'CloudPCsArea' {
                    $cloudChoice = Read-W365CliChoice -Prompt 'Cloud PCs' -Choices @(
                        ('{0,-28} {1}' -f 'Browse and manage', 'Open Cloud PC list, details, and inline actions')
                        ('{0,-28} {1}' -f 'Resize a Cloud PC', 'Pick a Cloud PC and target service plan')
                        ('{0,-28} {1}' -f 'Disk space', 'View free, used, total, and last sync')
                        ('{0,-28} {1}' -f 'Snapshots', 'Browse restore point snapshots')
                        ('{0,-28} {1}' -f 'Back', 'Return to main menu')
                    ) -AllowBack -Breadcrumb @('W365CLI','Cloud PCs') -HeaderScript {
                        Show-W365CliBanner -Connection $connection
                        Write-Host 'Cloud PCs: inventory, lifecycle actions, disk health, and remote action status.' -ForegroundColor DarkGray
                    }

                    switch ($cloudChoice) {
                        0 { Show-W365CloudPC -Browse | Out-Null }
                        1 { Invoke-W365Resize }
                        2 { Show-W365DiskSpace -Browse | Out-Null }
                        3 { Show-W365Snapshot -Browse | Out-Null }
                        default { }
                    }
                }
                'ProvisioningArea' {
                    $provisioningChoice = Read-W365CliChoice -Prompt 'Provisioning' -Choices @(
                        ('{0,-28} {1}' -f 'Provisioning policies', 'View, export, copy, delete, and inspect policy Cloud PCs')
                        ('{0,-28} {1}' -f 'Maintenance windows', 'View maintenance windows and assignments')
                        ('{0,-28} {1}' -f 'Create maintenance window', 'Create a weekday/weekend maintenance window')
                        ('{0,-28} {1}' -f 'Back', 'Return to main menu')
                    ) -AllowBack -Breadcrumb @('W365CLI','Provisioning') -HeaderScript {
                        Show-W365CliBanner -Connection $connection
                        Write-Host 'Provisioning: policy configuration, assignment visibility, and maintenance controls.' -ForegroundColor DarkGray
                    }

                    switch ($provisioningChoice) {
                        0 { Show-W365ProvisioningPolicy -Browse | Out-Null }
                        1 { Show-W365MaintenanceWindow -Browse | Out-Null }
                        2 { Invoke-W365MaintenanceWindowCreate }
                        default { }
                    }
                }
                'ReportsArea' {
                    $reportChoice = Read-W365CliChoice -Prompt 'Reports' -Choices @(
                        ('{0,-28} {1}' -f 'Usage', 'Who is signed in, idle days, and active sessions')
                        ('{0,-28} {1}' -f 'Connectivity history', 'Pick a Cloud PC and view connection events')
                        ('{0,-28} {1}' -f 'Launch details', 'Launch URLs, Windows App URI, Switch compatibility')
                        ('{0,-28} {1}' -f 'Cloud PC reports', 'Graph report streams with top-row selection')
                        ('{0,-28} {1}' -f 'Back', 'Return to main menu')
                    ) -AllowBack -Breadcrumb @('W365CLI','Reports') -HeaderScript {
                        Show-W365CliBanner -Connection $connection
                        Write-Host 'Reports: usage, connection history, launch details, and Graph report streams.' -ForegroundColor DarkGray
                    }

                    switch ($reportChoice) {
                        0 { Show-W365Usage -Browse | Out-Null }
                        1 { Show-W365ConnectivityHistory -Browse | Out-Null }
                        2 { Show-W365LaunchDetail -Browse | Out-Null }
                        3 { Show-W365Report -Browse | Out-Null }
                        default { }
                    }
                }
                'CloudAppsArea' {
                    Show-W365CloudApp -Status All -Browse | Out-Null
                }
                'CatalogArea' {
                    $catalogChoice = Read-W365CliChoice -Prompt 'Catalog' -Choices @(
                        ('{0,-28} {1}' -f 'Service plans', 'Browse vCPU, RAM, storage, and profile sizes')
                        ('{0,-28} {1}' -f 'Gallery images', 'Browse image status, SKU, size, and lifecycle dates')
                        ('{0,-28} {1}' -f 'Custom images', 'Browse tenant-uploaded Cloud PC images')
                        ('{0,-28} {1}' -f 'Supported regions', 'Browse available Windows 365 regions')
                        ('{0,-28} {1}' -f 'Licensing allotments', 'Browse allotted, consumed, and available capacity')
                        ('{0,-28} {1}' -f 'Back', 'Return to main menu')
                    ) -AllowBack -Breadcrumb @('W365CLI','Catalog') -HeaderScript {
                        Show-W365CliBanner -Connection $connection
                        Write-Host 'Catalog: plans and images used when provisioning or resizing Cloud PCs.' -ForegroundColor DarkGray
                    }

                    switch ($catalogChoice) {
                        0 { Show-W365ServicePlan -Browse | Out-Null }
                        1 { Show-W365GalleryImage -Browse | Out-Null }
                        2 { Show-W365CustomImage -Browse | Out-Null }
                        3 { Show-W365SupportedRegion -Browse | Out-Null }
                        4 { Show-W365LicensingAllotment -Browse | Out-Null }
                        default { }
                    }
                }
                'TenantArea' {
                    $tenantChoice = Read-W365CliChoice -Prompt 'Tenant settings' -Choices @(
                        ('{0,-28} {1}' -f 'Organization settings', 'View tenant-wide Windows 365 defaults')
                        ('{0,-28} {1}' -f 'Setting profiles', 'View Cloud PC setting profiles and assignments')
                        ('{0,-28} {1}' -f 'User settings', 'View restore/reset/local admin user settings')
                        ('{0,-28} {1}' -f 'Back', 'Return to main menu')
                    ) -AllowBack -Breadcrumb @('W365CLI','Tenant settings') -HeaderScript {
                        Show-W365CliBanner -Connection $connection
                        Write-Host 'Tenant settings: global Windows 365 defaults and platform behavior.' -ForegroundColor DarkGray
                    }

                    switch ($tenantChoice) {
                        0 { Show-W365OrganizationSetting -Browse | Out-Null }
                        1 { Show-W365SettingProfile -Browse | Out-Null }
                        2 { Show-W365UserSetting -Browse | Out-Null }
                        default { }
                    }
                }
                'ConnectionArea' {
                    $connectionItems = [System.Collections.Generic.List[object]]::new()
                    $connectionItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f $(if ($connection) { 'Reconnect' } else { 'Connect' }), 'Authenticate to Microsoft Graph for Windows 365'); Action = 'Connect' })
                    if ($connection) {
                        $connectionItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f 'Disconnect', 'Sign out of the current Microsoft Graph context'); Action = 'Disconnect' })
                    }
                    $connectionItems.Add([pscustomobject]@{ Label = ('{0,-28} {1}' -f 'Back', 'Return to main menu'); Action = 'Back' })

                    $connectChoice = Read-W365CliChoice -Prompt 'Connection' -Choices @($connectionItems.Label) -AllowBack -Breadcrumb @('W365CLI','Connection') -HeaderScript {
                        Show-W365CliBanner -Connection $connection
                        Write-Host 'Connection: connect, reconnect, or disconnect Microsoft Graph account context.' -ForegroundColor DarkGray
                    }

                    if ($connectChoice -ge 0) {
                        switch ($connectionItems[$connectChoice].Action) {
                            'Connect' { Connect-W365CliSession -Force:([bool]$connection) }
                            'Disconnect' { Disconnect-W365CliSession }
                            default { }
                        }
                    }
                }
                default {
                    return
                }
            }
        }
    }

    end { }
}
