function Show-W365ConnectivityHistory {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.CloudPCConnectivityEvent')]
    param(
        [object]$CloudPC,
        [switch]$Browse
    )

    begin { Import-W365CliWindowsCloudPC }

    process {
        $target = if ($CloudPC) { $CloudPC } else { Show-W365CloudPC }
        if (-not $target) { return }
        $items = @($target | Get-CloudPCConnectivityHistory | Sort-Object EventDateTime -Descending)
        if ($items.Count -eq 0) { Write-Warning 'No connectivity history rows were returned.'; return }

        $columnHeader = '{0} {1} {2} {3} {4}' -f
            (Format-W365CliText -Text 'Time' -Width 22),
            (Format-W365CliText -Text 'Type' -Width 18),
            (Format-W365CliText -Text 'Event' -Width 28),
            (Format-W365CliText -Text 'Result' -Width 12),
            (Format-W365CliText -Text 'Message' -Width 50)

        Select-W365CliObject -InputObject $items -Title "Connectivity history for $($target.Name)" -DisplayProperties @(
            'EventDateTime','EventType','EventName','EventResult','Message'
        ) -FilterProperties @('EventType','EventName','EventResult','Message') -LabelScript {
            param($Event)
            '{0} {1} {2} {3} {4}' -f
                (Format-W365CliText -Text $Event.EventDateTime -Width 22),
                (Format-W365CliText -Text $Event.EventType -Width 18),
                (Format-W365CliText -Text $Event.EventName -Width 28),
                (Format-W365CliText -Text $Event.EventResult -Width 12),
                (Format-W365CliText -Text $Event.Message -Width 50)
        } -DetailScript {
            param($Event)
            $Event.PSObject.Properties | Where-Object Name -notlike 'Raw*' | ForEach-Object { "{0}: {1}" -f $_.Name, $_.Value }
        } -RefreshScript {
            @($target | Get-CloudPCConnectivityHistory | Sort-Object EventDateTime -Descending)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Reports','Connectivity history')
    }
}
