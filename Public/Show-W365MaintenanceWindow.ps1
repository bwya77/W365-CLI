function Show-W365MaintenanceWindow {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.MaintenanceWindow')]
    param(
        [switch]$Browse
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $items = @(Get-CloudPCMaintenanceWindow -IncludeAssignments | Sort-Object DisplayName)
        if ($items.Count -eq 0) {
            Write-Warning 'No maintenance windows were returned.'
            return
        }

        $title = if ($Browse) { 'Windows 365 maintenance windows' } else { 'Pick a Windows 365 maintenance window' }
        $columnHeader = '{0} {1} {2} {3}' -f
            (Format-W365CliText -Text 'Name' -Width 36),
            (Format-W365CliText -Text 'Schedule' -Width 54),
            (Format-W365CliText -Text 'Lead' -Width 8),
            (Format-W365CliText -Text 'Assigned groups' -Width 34)

        Select-W365CliObject -InputObject $items -Title $title -DisplayProperties @(
            'DisplayName',
            'ScheduleSummary',
            'NotificationLeadTimeInMinutes',
            'AssignedGroupNames'
        ) -FilterProperties @(
            'DisplayName',
            'Description',
            'ScheduleSummary',
            'AssignedGroupNames'
        ) -LabelScript {
            param($Window)

            $groups = @($Window.AssignedGroupNames) -join ', '
            '{0} {1} {2} {3}' -f
                (Format-W365CliText -Text $Window.DisplayName -Width 36),
                (Format-W365CliText -Text $Window.ScheduleSummary -Width 54),
                (Format-W365CliText -Text "$($Window.NotificationLeadTimeInMinutes)m" -Width 8),
                (Format-W365CliText -Text $groups -Width 34)
        } -DetailScript {
            param($Window)

            @(
                "Name:                       $($Window.DisplayName)"
                "Description:                $($Window.Description)"
                "Notification lead minutes:  $($Window.NotificationLeadTimeInMinutes)"
                "Schedule:                   $($Window.ScheduleSummary)"
                "Assigned groups:            $(@($Window.AssignedGroupNames) -join ', ')"
                "Maintenance window ID:      $($Window.Id)"
            )
        } -ActionScript {
            param($Window, $Action)

            Invoke-W365MaintenanceWindowAction -MaintenanceWindow $Window -Action $Action
        } -ActionLabels @(
            'View assigned group members',
            'Edit',
            'Delete'
        ) -SummaryScript {
            param(
                [object[]]$AllItems,
                [object[]]$VisibleItems,
                [string]$Filter,
                [int]$SelectedIndex
            )

            @(
                "Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))"
                $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
            )
        } -RefreshScript {
            @(Get-CloudPCMaintenanceWindow -IncludeAssignments | Sort-Object DisplayName)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Provisioning','Maintenance windows')
    }

    end { }
}
