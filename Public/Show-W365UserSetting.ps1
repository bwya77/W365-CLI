function Show-W365UserSetting {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.UserSetting')]
    param([switch]$Browse)

    begin { Import-W365CliWindowsCloudPC }

    process {
        $items = @(Get-CloudPCUserSetting -IncludeAssignments | Sort-Object DisplayName)
        if ($items.Count -eq 0) { Write-Warning 'No user settings were returned.'; return }
        $columnHeader = '{0} {1} {2} {3} {4} {5}' -f (Format-W365CliText -Text 'Name' -Width 38),(Format-W365CliText -Text 'SelfSvc' -Width 8),(Format-W365CliText -Text 'Admin' -Width 8),(Format-W365CliText -Text 'Reset' -Width 8),(Format-W365CliText -Text 'Restore' -Width 9),(Format-W365CliText -Text 'DR' -Width 8)
        Select-W365CliObject -InputObject $items -Title 'Windows 365 user settings' -DisplayProperties @('DisplayName','SelfServiceEnabled','LocalAdminEnabled','ResetEnabled','UserRestoreEnabled','CrossRegionDisasterRecoveryEnabled') -FilterProperties @('DisplayName','ProvisioningSourceType') -LabelScript {
            param($Setting)
            '{0} {1} {2} {3} {4} {5}' -f (Format-W365CliText -Text $Setting.DisplayName -Width 38),(Format-W365CliText -Text $Setting.SelfServiceEnabled -Width 8),(Format-W365CliText -Text $Setting.LocalAdminEnabled -Width 8),(Format-W365CliText -Text $Setting.ResetEnabled -Width 8),(Format-W365CliText -Text $Setting.UserRestoreEnabled -Width 9),(Format-W365CliText -Text $Setting.CrossRegionDisasterRecoveryEnabled -Width 8)
        } -DetailScript {
            param($Setting)
            $Setting.PSObject.Properties | Where-Object Name -notlike 'Raw*' | ForEach-Object { "{0}: {1}" -f $_.Name, $_.Value }
        } -RefreshScript {
            @(Get-CloudPCUserSetting -IncludeAssignments | Sort-Object DisplayName)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Tenant settings','User settings')
    }
}
