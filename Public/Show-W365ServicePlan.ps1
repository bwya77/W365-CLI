function Show-W365ServicePlan {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.ServicePlan')]
    param(
        [ValidateSet('enterprise','business')]
        [string]$Type,

        [switch]$Browse
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $servicePlanParams = @{}
        if ($PSBoundParameters.ContainsKey('Type')) {
            $servicePlanParams.Type = $Type
        }

        $plans = @(Get-CloudPCServicePlan @servicePlanParams | Sort-Object Type, VCpuCount, RamGB, StorageGB, DisplayName)
        if ($plans.Count -eq 0) {
            Write-Warning 'No service plans were returned.'
            return
        }

        $browserTitle = if ($Browse) { 'Windows 365 service plans' } else { 'Pick a Windows 365 service plan' }
        $columnHeader = '{0} {1} {2} {3} {4} {5}' -f
            (Format-W365CliText -Text 'Name' -Width 44),
            (Format-W365CliText -Text 'Type' -Width 12),
            (Format-W365CliText -Text 'vCPU' -Width 6),
            (Format-W365CliText -Text 'RAM' -Width 8),
            (Format-W365CliText -Text 'Storage' -Width 10),
            (Format-W365CliText -Text 'Profile' -Width 10)

        Select-W365CliObject -InputObject $plans -Title $browserTitle -DisplayProperties @(
            'DisplayName',
            'Type',
            'VCpuCount',
            'RamGB',
            'StorageGB',
            'UserProfileGB'
        ) -FilterProperties @(
            'DisplayName',
            'Type',
            'VCpuCount',
            'RamGB',
            'StorageGB'
        ) -LabelScript {
            param($Plan)

            '{0} {1} {2} {3} {4} {5}' -f
                (Format-W365CliText -Text $Plan.DisplayName -Width 44),
                (Format-W365CliText -Text $Plan.Type -Width 12),
                (Format-W365CliText -Text $Plan.VCpuCount -Width 6),
                (Format-W365CliText -Text "$($Plan.RamGB) GB" -Width 8),
                (Format-W365CliText -Text "$($Plan.StorageGB) GB" -Width 10),
                (Format-W365CliText -Text "$($Plan.UserProfileGB) GB" -Width 10)
        } -DetailScript {
            param($Plan)

            @(
                "Name:             $($Plan.DisplayName)"
                "Type:             $($Plan.Type)"
                "vCPU:             $($Plan.VCpuCount)"
                "RAM:              $($Plan.RamGB) GB"
                "Storage:          $($Plan.StorageGB) GB"
                "Profile storage:  $($Plan.UserProfileGB) GB"
                "Service plan ID:  $($Plan.Id)"
            )
        } -SummaryScript {
            param(
                [object[]]$AllItems,
                [object[]]$VisibleItems,
                [string]$Filter,
                [int]$SelectedIndex
            )

            $typeSummary = @(
                $AllItems |
                    Group-Object -Property Type |
                    Sort-Object Name |
                    ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }
            ) -join ' | '

            $vcpuSummary = @(
                $VisibleItems |
                    Group-Object -Property VCpuCount |
                    Sort-Object { [int]$_.Name } |
                    ForEach-Object { '{0}vCPU: {1}' -f $_.Name, $_.Count }
            ) -join ' | '

            $storageSummary = @(
                $VisibleItems |
                    Group-Object -Property StorageGB |
                    Sort-Object { [int]$_.Name } |
                    ForEach-Object { '{0}GB: {1}' -f $_.Name, $_.Count }
            ) -join ' | '

            @(
                "Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))"
                "Types: $typeSummary"
                "Visible vCPU: $vcpuSummary"
                "Visible storage: $storageSummary"
                $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
            )
        } -RefreshScript {
            @(Get-CloudPCServicePlan @servicePlanParams | Sort-Object Type, VCpuCount, RamGB, StorageGB, DisplayName)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Catalog','Service plans')
    }

    end { }
}
