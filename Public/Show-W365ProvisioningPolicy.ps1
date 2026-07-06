function Show-W365ProvisioningPolicy {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.ProvisioningPolicy')]
    param(
        [switch]$Browse
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $policies = @(Get-CloudPCProvisioningPolicy | Sort-Object DisplayName)
        if ($policies.Count -eq 0) {
            Write-Warning 'No provisioning policies were returned.'
            return
        }

        $title = if ($Browse) { 'Windows 365 provisioning policies' } else { 'Pick a Windows 365 provisioning policy' }
        $columnHeader = '{0} {1} {2} {3} {4} {5}' -f
            (Format-W365CliText -Text 'Name' -Width 40),
            (Format-W365CliText -Text 'Type' -Width 12),
            (Format-W365CliText -Text 'Image' -Width 28),
            (Format-W365CliText -Text 'Join' -Width 16),
            (Format-W365CliText -Text 'SSO' -Width 5),
            (Format-W365CliText -Text 'Groups' -Width 28)

        Select-W365CliObject -InputObject $policies -Title $title -DisplayProperties @(
            'DisplayName',
            'ProvisioningType',
            'ImageDisplayName',
            'DomainJoinTypes',
            'AssignedGroupNames'
        ) -FilterProperties @(
            'DisplayName',
            'Description',
            'ProvisioningType',
            'ImageDisplayName',
            'ImageType',
            'DomainJoinTypes',
            'CloudPcNamingTemplate',
            'CloudPcGroupDisplayName',
            'AssignedGroupNames'
        ) -LabelScript {
            param($Policy)

            $groups = @($Policy.AssignedGroupNames) -join ', '
            '{0} {1} {2} {3} {4} {5}' -f
                (Format-W365CliText -Text $Policy.DisplayName -Width 40),
                (Format-W365CliText -Text $Policy.ProvisioningType -Width 12),
                (Format-W365CliText -Text $Policy.ImageDisplayName -Width 28),
                (Format-W365CliText -Text $Policy.DomainJoinTypes -Width 16),
                (Format-W365CliText -Text $Policy.EnableSingleSignOn -Width 5),
                (Format-W365CliText -Text $groups -Width 28)
        } -DetailScript {
            param($Policy)

            @(
                "Name:                   $($Policy.DisplayName)"
                "Description:            $($Policy.Description)"
                "Provisioning type:      $($Policy.ProvisioningType)"
                "Image:                  $($Policy.ImageDisplayName)"
                "Image type:             $($Policy.ImageType)"
                "Domain join:            $($Policy.DomainJoinTypes)"
                "Single sign-on:         $($Policy.EnableSingleSignOn)"
                "Local admin enabled:    $($Policy.LocalAdminEnabled)"
                "Naming template:        $($Policy.CloudPcNamingTemplate)"
                "Cloud PC group:         $($Policy.CloudPcGroupDisplayName)"
                "Managed by:             $($Policy.ManagedBy)"
                "Grace period hours:     $($Policy.GracePeriodInHours)"
                "Assigned groups:        $(@($Policy.AssignedGroupNames) -join ', ')"
                "Policy ID:              $($Policy.Id)"
            )
        } -ActionScript {
            param($Policy, $Action)

            Invoke-W365ProvisioningPolicyAction -Policy $Policy -Action $Action
        } -ActionLabels @(
            'View Cloud PCs',
            'Export',
            'Create copy',
            'Reprovision policy Cloud PCs',
            'Delete'
        ) -SummaryScript {
            param(
                [object[]]$AllItems,
                [object[]]$VisibleItems,
                [string]$Filter,
                [int]$SelectedIndex
            )

            $typeSummary = @(
                $AllItems |
                    Group-Object -Property ProvisioningType |
                    Sort-Object Name |
                    ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }
            ) -join ' | '

            $joinSummary = @(
                $AllItems |
                    Group-Object -Property DomainJoinTypes |
                    Sort-Object Name |
                    ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }
            ) -join ' | '

            @(
                "Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))"
                "Types: $typeSummary"
                "Join: $joinSummary"
                $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
            )
        } -RefreshScript {
            @(Get-CloudPCProvisioningPolicy | Sort-Object DisplayName)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Provisioning','Provisioning policies')
    }

    end { }
}
