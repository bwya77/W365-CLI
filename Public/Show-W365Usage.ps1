function Show-W365Usage {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.CloudPCUsage')]
    param([switch]$Browse)

    begin { Import-W365CliWindowsCloudPC }

    process {
        Clear-Host
        Write-Host ''
        Write-Host 'Loading Cloud PC usage...' -ForegroundColor Cyan
        Write-Host 'This can take a while because real-time status, connectivity history, and Intune inventory may be queried.' -ForegroundColor DarkGray
        $items = @(Get-W365UsageData)
        Clear-Host
        if ($items.Count -eq 0) { Write-Warning 'No usage rows were returned.'; return }

        $columnHeader = '{0} {1} {2} {3} {4} {5}' -f
            (Format-W365CliText -Text 'Cloud PC' -Width 34),
            (Format-W365CliText -Text 'Usage' -Width 12),
            (Format-W365CliText -Text 'Sign-in' -Width 14),
            (Format-W365CliText -Text 'Days idle' -Width 10),
            (Format-W365CliText -Text 'Current user' -Width 34),
            (Format-W365CliText -Text 'Last active' -Width 22)

        Select-W365CliObject -InputObject $items -Title 'Windows 365 Cloud PC usage' -DisplayProperties @(
            'CloudPcName','UsageStatus','SignInStatus','DaysSinceLastSignIn','CurrentUserUpn','LastActiveTime'
        ) -FilterProperties @(
            'CloudPcName','ProvisioningType','ProvisioningPolicyName','UsageStatus','SignInStatus','AssignedUserUpn','CurrentUserUpn'
        ) -LabelScript {
            param($Usage)
            '{0} {1} {2} {3} {4} {5}' -f
                (Format-W365CliText -Text $Usage.CloudPcName -Width 34),
                (Format-W365CliText -Text $Usage.UsageStatus -Width 12),
                (Format-W365CliText -Text $Usage.SignInStatus -Width 14),
                (Format-W365CliText -Text $Usage.DaysSinceLastSignIn -Width 10),
                (Format-W365CliText -Text $Usage.CurrentUserUpn -Width 34),
                (Format-W365CliText -Text $Usage.LastActiveTime -Width 22)
        } -DetailScript {
            param($Usage)
            $Usage.PSObject.Properties | Where-Object Name -notlike 'Raw*' | ForEach-Object { "{0}: {1}" -f $_.Name, $_.Value }
        } -ActionScript {
            param($Usage, $Action)

            $cloudPc = Resolve-W365CloudPCFromRow -InputObject $Usage
            if (-not $cloudPc) {
                Write-Warning 'Could not resolve this usage row back to a Cloud PC.'
                [Console]::ReadKey($true) | Out-Null
                return
            }

            Invoke-W365CloudPCAction -CloudPC $cloudPc -Action $Action
        } -ActionLabelsScript {
            param($Usage)

            $cloudPc = Resolve-W365CloudPCFromRow -InputObject $Usage
            if ($cloudPc) {
                Get-W365CloudPCActionItem -CloudPC $cloudPc
            }
            else {
                @(
                    [pscustomobject]@{ Label = 'Cloud PC actions unavailable'; Action = 'None'; Disabled = $true; Reason = 'could not resolve Cloud PC' }
                )
            }
        } -SummaryScript {
            param([object[]]$AllItems,[object[]]$VisibleItems,[string]$Filter,[int]$SelectedIndex)
            $usageSummary = @($AllItems | Group-Object UsageStatus | Sort-Object Name | ForEach-Object { '{0}: {1}' -f $(if ($_.Name) { $_.Name } else { 'Unknown' }), $_.Count }) -join ' | '
            @("Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))","Usage: $usageSummary",$(if ($Filter) { "Search: $Filter" } else { 'Search: none' }))
        } -RefreshScript {
            Clear-Host
            Write-Host ''
            Write-Host 'Refreshing Cloud PC usage...' -ForegroundColor Cyan
            $refreshed = @(Get-W365UsageData)
            Clear-Host
            $refreshed
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Reports','Usage')
    }
}
