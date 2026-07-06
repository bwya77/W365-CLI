function Show-W365CloudPCRemoteActionHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CloudPC
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $results = @($CloudPC | Get-CloudPCRemoteActionResult)
        if ($results.Count -eq 0) {
            Write-Warning 'No remote action history was returned for this Cloud PC.'
            Write-Host 'Press any key to continue...' -ForegroundColor DarkGray
            [Console]::ReadKey($true) | Out-Null
            return
        }

        $columnHeader = '{0} {1} {2} {3} {4} {5}' -f
            (Format-W365CliText -Text 'Action' -Width 14),
            (Format-W365CliText -Text 'State' -Width 12),
            (Format-W365CliText -Text 'Started' -Width 22),
            (Format-W365CliText -Text 'Updated' -Width 22),
            (Format-W365CliText -Text 'Code' -Width 12),
            (Format-W365CliText -Text 'Message' -Width 40)

        Select-W365CliObject -InputObject $results -Title "Remote action history for $($CloudPC.Name)" -DisplayProperties @(
            'ActionName',
            'ActionState',
            'StartDateTime',
            'LastUpdatedDateTime',
            'StatusCode',
            'StatusMessage'
        ) -FilterProperties @(
            'ActionName',
            'ActionState',
            'StatusCode',
            'StatusMessage'
        ) -LabelScript {
            param($Result)

            '{0} {1} {2} {3} {4} {5}' -f
                (Format-W365CliText -Text $Result.ActionName -Width 14),
                (Format-W365CliText -Text $Result.ActionState -Width 12),
                (Format-W365CliText -Text $Result.StartDateTime -Width 22),
                (Format-W365CliText -Text $Result.LastUpdatedDateTime -Width 22),
                (Format-W365CliText -Text $Result.StatusCode -Width 12),
                (Format-W365CliText -Text $Result.StatusMessage -Width 40)
        } -DetailScript {
            param($Result)

            @(
                "Action:        $($Result.ActionName)"
                "State:         $($Result.ActionState)"
                "Started:       $($Result.StartDateTime)"
                "Updated:       $($Result.LastUpdatedDateTime)"
                "Status code:   $($Result.StatusCode)"
                "Message:       $($Result.StatusMessage)"
                "Has downtime:  $($Result.HasDownTime)"
                "Managed ID:    $($Result.ManagedDeviceId)"
                "Cloud PC ID:   $($Result.CloudPcId)"
            )
        } -SummaryScript {
            param(
                [object[]]$AllItems,
                [object[]]$VisibleItems,
                [string]$Filter,
                [int]$SelectedIndex
            )

            $stateSummary = @(
                $AllItems |
                    Group-Object -Property ActionState |
                    Sort-Object Name |
                    ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }
            ) -join ' | '

            @(
                "Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))"
                "States: $stateSummary"
                $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
            )
        } -RefreshScript {
            @($CloudPC | Get-CloudPCRemoteActionResult)
        } -ColumnHeader $columnHeader -PageSize 12 -ViewOnly -Breadcrumb @('W365CLI','Cloud PCs','Remote action history') | Out-Null
    }

    end { }
}
