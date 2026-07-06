function Show-W365SupportedRegion {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.SupportedRegion')]
    param([switch]$Browse)

    begin { Import-W365CliWindowsCloudPC }

    process {
        $items = @(Get-CloudPCSupportedRegion | Sort-Object RegionGroup, DisplayName)
        if ($items.Count -eq 0) { Write-Warning 'No supported regions were returned.'; return }
        $columnHeader = '{0} {1} {2} {3} {4}' -f (Format-W365CliText -Text 'Name' -Width 34),(Format-W365CliText -Text 'Status' -Width 12),(Format-W365CliText -Text 'Solution' -Width 16),(Format-W365CliText -Text 'Group' -Width 20),(Format-W365CliText -Text 'Geo' -Width 20)
        Select-W365CliObject -InputObject $items -Title 'Windows 365 supported regions' -DisplayProperties @('DisplayName','RegionStatus','SupportedSolution','RegionGroup','GeographicLocationType') -FilterProperties @('DisplayName','RegionStatus','SupportedSolution','RegionGroup','GeographicLocationType') -LabelScript {
            param($Region)
            '{0} {1} {2} {3} {4}' -f (Format-W365CliText -Text $Region.DisplayName -Width 34),(Format-W365CliText -Text $Region.RegionStatus -Width 12),(Format-W365CliText -Text $Region.SupportedSolution -Width 16),(Format-W365CliText -Text $Region.RegionGroup -Width 20),(Format-W365CliText -Text $Region.GeographicLocationType -Width 20)
        } -DetailScript {
            param($Region)
            @("Name: $($Region.DisplayName)","Status: $($Region.RegionStatus)","Supported solution: $($Region.SupportedSolution)","Region group: $($Region.RegionGroup)","Geographic type: $($Region.GeographicLocationType)","Region ID: $($Region.Id)")
        } -SummaryScript {
            param([object[]]$AllItems,[object[]]$VisibleItems,[string]$Filter,[int]$SelectedIndex)
            $statusSummary = @($AllItems | Group-Object RegionStatus | Sort-Object Name | ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }) -join ' | '
            @("Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))","Status: $statusSummary",$(if ($Filter) { "Search: $Filter" } else { 'Search: none' }))
        } -RefreshScript {
            @(Get-CloudPCSupportedRegion | Sort-Object RegionGroup, DisplayName)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Catalog','Supported regions')
    }
}
