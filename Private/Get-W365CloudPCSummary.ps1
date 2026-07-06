function Get-W365CloudPCSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$AllItems,

        [Parameter(Mandatory)]
        [object[]]$VisibleItems,

        [string]$Filter,

        [int]$SelectedIndex
    )

    begin { }

    process {
        $typeSummary = @(
            $AllItems |
                Group-Object -Property ProvisioningType |
                Sort-Object Name |
                ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }
        ) -join ' | '

        $statusSummary = @(
            $AllItems |
                Group-Object -Property ProvisioningStatus |
                Sort-Object Name |
                ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }
        ) -join ' | '

        @(
            "Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))"
            "Types: $typeSummary"
            "Status: $statusSummary"
            $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
        )
    }

    end { }
}
