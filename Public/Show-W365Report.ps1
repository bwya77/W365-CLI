function Show-W365Report {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.ReportRow')]
    param([switch]$Browse)

    begin { Import-W365CliWindowsCloudPC }

    process {
        $reportNames = @(
            'remoteConnectionHistoricalReports',
            'dailyAggregatedRemoteConnectionReports',
            'totalAggregatedRemoteConnectionReports',
            'frontlineLicenseUsageReport',
            'frontlineLicenseUsageRealTimeReport',
            'frontlineLicenseHourlyUsageReport',
            'frontlineRealtimeUserConnectionsReport',
            'inaccessibleCloudPcReports',
            'actionStatusReport',
            'performanceTrendReport',
            'regionalConnectionQualityTrendReport',
            'cloudPcUsageCategoryReport',
            'realTimeRemoteConnectionStatus'
        )
        $choice = Read-W365CliChoice -Prompt 'Cloud PC report' -Choices $reportNames -AllowBack -Breadcrumb @('W365CLI','Reports','Cloud PC reports')
        if ($choice -lt 0) { return }
        $reportName = $reportNames[$choice]
        $topInput = Read-Host 'Top rows [50]'
        $top = if ([string]::IsNullOrWhiteSpace($topInput)) { 50 } else { [int]$topInput }

        $items = @(Invoke-W365CliSpinner -Message "Loading report $reportName." -ScriptBlock { Get-CloudPCReport -ReportName $reportName -Top $top })
        if ($items.Count -eq 0) { Write-Warning 'No report rows were returned.'; return }

        Select-W365CliObject -InputObject $items -Title "Report: $reportName" -DisplayProperties @('ManagedDeviceName','CloudPcName','SignInStatus','LastActiveTime','Timestamp','DisplayName','Status') -FilterProperties @('ManagedDeviceName','CloudPcName','DisplayName','SignInStatus','Status') -LabelScript {
            param($Row)
            $values = @($Row.ManagedDeviceName, $Row.CloudPcName, $Row.DisplayName, $Row.SignInStatus, $Row.Status, $Row.Timestamp, $Row.LastActiveTime) | Where-Object { $_ }
            Format-W365CliText -Text ($values -join ' | ') -Width 140
        } -DetailScript {
            param($Row)
            $Row.PSObject.Properties | Where-Object Name -notlike 'Raw*' | ForEach-Object { "{0}: {1}" -f $_.Name, $_.Value }
        } -RefreshScript {
            @(Invoke-W365CliSpinner -Message "Refreshing report $reportName." -ScriptBlock { Get-CloudPCReport -ReportName $reportName -Top $top })
        } -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Reports','Cloud PC reports')
    }
}
