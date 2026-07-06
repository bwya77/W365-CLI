function Show-W365CloudApp {
    [CmdletBinding()]
    [OutputType('W365CLI.CloudApp')]
    param(
        [ValidateSet('All','Ready','Failed')]
        [string]$Status = 'All',

        [switch]$Browse
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $statusChoice = $Status

        $items = @(Get-W365CloudAppData -Status $statusChoice | Sort-Object LastPublishedDateTime -Descending)
        if ($items.Count -eq 0) {
            Write-Warning 'No cloud apps were returned.'
            return
        }

        $columnHeader = '{0} {1} {2} {3} {4}' -f
            (Format-W365CliText -Text 'Status' -Width 12),
            (Format-W365CliText -Text 'Name' -Width 52),
            (Format-W365CliText -Text 'Publisher' -Width 24),
            (Format-W365CliText -Text 'Published' -Width 22),
            (Format-W365CliText -Text 'Added' -Width 22)

        $title = if ($statusChoice -eq 'All') { 'Windows 365 cloud apps' } else { "Windows 365 cloud apps - $statusChoice" }

        Select-W365CliObject -InputObject $items -Title $title -DisplayProperties @(
            'DisplayName',
            'AppStatus',
            'Publisher',
            'LastPublishedDateTime',
            'AddedDateTime'
        ) -FilterProperties @(
            'DisplayName',
            'AppStatus',
            'AppType',
            'Publisher',
            'Version',
            'DiscoveredAppName'
        ) -LabelScript {
            param($App)

            '{0} {1} {2} {3} {4}' -f
                (Format-W365CliText -Text $App.AppStatus -Width 12),
                (Format-W365CliText -Text $App.DisplayName -Width 52),
                (Format-W365CliText -Text $App.Publisher -Width 24),
                (Format-W365CliText -Text $App.LastPublishedDateTime -Width 22),
                (Format-W365CliText -Text $App.AddedDateTime -Width 22)
        } -DetailScript {
            param($App)

            @(
                "Name:            $($App.DisplayName)"
                "Status:          $($App.AppStatus)"
                "Type:            $($App.AppType)"
                "Publisher:       $($App.Publisher)"
                "Version:         $($App.Version)"
                "Discovered app:  $($App.DiscoveredAppName)"
                "Added:           $($App.AddedDateTime)"
                "Published:       $($App.LastPublishedDateTime)"
                "Description:     $($App.Description)"
                "Cloud app ID:    $($App.Id)"
            )
        } -ActionScript {
            param($App, $Action)

            Invoke-W365CloudAppAction -CloudApp $App -Action $Action
        } -ActionLabelsScript {
            param($App)

            $isReady = $App.AppStatus -eq 'ready'
            $isPublished = $App.AppStatus -eq 'published'
            @(
                [pscustomobject]@{ Label = 'Publish'; Action = 'Publish'; Disabled = (-not $isReady); Reason = if ($isReady) { $null } else { "status is $($App.AppStatus)" } }
                [pscustomobject]@{ Label = 'Unpublish'; Action = 'Unpublish'; Disabled = (-not $isPublished); Reason = if ($isPublished) { $null } else { "status is $($App.AppStatus)" } }
            )
        } -SummaryScript {
            param(
                [object[]]$AllItems,
                [object[]]$VisibleItems,
                [string]$Filter,
                [int]$SelectedIndex
            )

            $statusSummary = @(
                $AllItems |
                    Group-Object -Property AppStatus |
                    Sort-Object Name |
                    ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }
            ) -join ' | '

            @(
                "Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))"
                "Status: $statusSummary"
                $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
            )
        } -RefreshScript {
            @(Get-W365CloudAppData -Status $statusChoice | Sort-Object LastPublishedDateTime -Descending)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Cloud Apps',"$statusChoice")
    }

    end { }
}
