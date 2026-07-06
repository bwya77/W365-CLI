function Show-W365Snapshot {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.Snapshot')]
    param(
        [object]$CloudPC,

        [switch]$Browse
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        Clear-Host
        Write-Host ''
        Write-Host 'Loading Cloud PC snapshots...' -ForegroundColor Cyan
        $items = @(Get-W365SnapshotData -CloudPC $CloudPC | Sort-Object CreatedDateTime -Descending)

        $title = if ($CloudPC) { "Snapshots for $($CloudPC.Name)" } else { 'Windows 365 snapshots' }
        $columnHeader = if ($CloudPC) {
            '{0} {1} {2} {3} {4}' -f
                (Format-W365CliText -Text 'Status' -Width 14),
                (Format-W365CliText -Text 'Type' -Width 12),
                (Format-W365CliText -Text 'Created' -Width 22),
                (Format-W365CliText -Text 'Expires' -Width 22),
                (Format-W365CliText -Text 'Health' -Width 14)
        }
        else {
            '{0} {1} {2} {3} {4} {5}' -f
                (Format-W365CliText -Text 'Cloud PC' -Width 34),
                (Format-W365CliText -Text 'Status' -Width 14),
                (Format-W365CliText -Text 'Type' -Width 12),
                (Format-W365CliText -Text 'Created' -Width 22),
                (Format-W365CliText -Text 'Expires' -Width 22),
                (Format-W365CliText -Text 'Health' -Width 14)
        }

        Select-W365CliObject -InputObject $items -Title $title -DisplayProperties @(
            'Status',
            'SnapshotType',
            'CreatedDateTime',
            'ExpirationDateTime',
            'HealthCheckStatus'
        ) -FilterProperties @(
            'Status',
            'SnapshotType',
            'HealthCheckStatus',
            'SnapshotId'
        ) -LabelScript {
            param($Snapshot)

            if ($CloudPC) {
                '{0} {1} {2} {3} {4}' -f
                    (Format-W365CliText -Text $Snapshot.Status -Width 14),
                    (Format-W365CliText -Text $Snapshot.SnapshotType -Width 12),
                    (Format-W365CliText -Text $Snapshot.CreatedDateTime -Width 22),
                    (Format-W365CliText -Text $Snapshot.ExpirationDateTime -Width 22),
                    (Format-W365CliText -Text $Snapshot.HealthCheckStatus -Width 14)
            }
            else {
                '{0} {1} {2} {3} {4} {5}' -f
                    (Format-W365CliText -Text $Snapshot.CloudPcName -Width 34),
                    (Format-W365CliText -Text $Snapshot.Status -Width 14),
                    (Format-W365CliText -Text $Snapshot.SnapshotType -Width 12),
                    (Format-W365CliText -Text $Snapshot.CreatedDateTime -Width 22),
                    (Format-W365CliText -Text $Snapshot.ExpirationDateTime -Width 22),
                    (Format-W365CliText -Text $Snapshot.HealthCheckStatus -Width 14)
            }
        } -DetailScript {
            param($Snapshot)

            @(
                "Cloud PC:       $($Snapshot.CloudPcName)"
                "Status:         $($Snapshot.Status)"
                "Type:           $($Snapshot.SnapshotType)"
                "Created:        $($Snapshot.CreatedDateTime)"
                "Last restored:  $($Snapshot.LastRestoredDateTime)"
                "Expires:        $($Snapshot.ExpirationDateTime)"
                "Health:         $($Snapshot.HealthCheckStatus)"
                "Snapshot ID:    $($Snapshot.SnapshotId)"
                "Cloud PC ID:    $($Snapshot.CloudPcId)"
            )
        } -ActionScript {
            param($Snapshot, $Action)

            Invoke-W365SnapshotAction -Snapshot $Snapshot -Action $Action
        } -ActionLabels @(
            'Restore Cloud PC from this snapshot',
            'Delete this snapshot'
        ) -ActionLabelsScript {
            param($Snapshot)

            @(
                [pscustomobject]@{ Label = 'Restore Cloud PC from this snapshot'; Action = 'Restore Cloud PC from this snapshot'; Disabled = (-not $Snapshot.SnapshotId); Reason = if ($Snapshot.SnapshotId) { $null } else { 'no snapshot selected' } }
                [pscustomobject]@{ Label = 'Delete this snapshot'; Action = 'Delete this snapshot'; Disabled = (-not $Snapshot.SnapshotId); Reason = if ($Snapshot.SnapshotId) { $null } else { 'no snapshot selected' } }
            )
        } -EmptyActionScript {
            param($Action)

            if ($Action -eq 'Create snapshot') {
                $snapshotSeed = [pscustomobject]@{
                    CloudPcId   = if ($CloudPC) { $CloudPC.Id } else { $null }
                    CloudPcName = if ($CloudPC) { $CloudPC.Name } else { $null }
                }
                Invoke-W365SnapshotAction -Snapshot $snapshotSeed -Action 'Create snapshot'
            }
        } -EmptyActionLabels @(
            'Create snapshot'
        ) -NewActionScript {
            param($Action)

            if ($Action -eq 'Create snapshot') {
                $snapshotSeed = [pscustomobject]@{
                    CloudPcId   = if ($CloudPC) { $CloudPC.Id } else { $null }
                    CloudPcName = if ($CloudPC) { $CloudPC.Name } else { $null }
                }
                Invoke-W365SnapshotAction -Snapshot $snapshotSeed -Action 'Create snapshot'
            }
        } -NewActionLabel 'Create snapshot' -SummaryScript {
            param(
                [object[]]$AllItems,
                [object[]]$VisibleItems,
                [string]$Filter,
                [int]$SelectedIndex
            )

            $realItems = @($AllItems)
            $statusSummary = if ($realItems.Count -gt 0) {
                @($realItems | Group-Object Status | Sort-Object Name | ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }) -join ' | '
            }
            else {
                'None: 0'
            }

            @(
                "Total: $($realItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))"
                "Status: $statusSummary"
                $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
            )
        } -RefreshScript {
            @(Get-W365SnapshotData -CloudPC $CloudPC | Sort-Object CreatedDateTime -Descending)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Cloud PCs','Snapshots')
    }

    end { }
}
