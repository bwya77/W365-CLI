function Invoke-W365MaintenanceWindowCreate {
    [CmdletBinding()]
    param()

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $displayName = Read-Host 'Display name'
        if ([string]::IsNullOrWhiteSpace($displayName)) {
            Write-Warning 'Create cancelled. Display name is required.'
            return
        }

        $description = Read-Host 'Description (optional)'
        $leadInput = Read-Host 'Notification lead time in minutes [60]'
        $lead = if ([string]::IsNullOrWhiteSpace($leadInput)) { 60 } else { [int]$leadInput }
        $weekdayStart = Read-Host 'Weekday start time HH:mm'
        $weekdayEnd = Read-Host 'Weekday end time HH:mm'
        $weekendStart = Read-Host 'Weekend start time HH:mm (blank = weekday start)'
        $weekendEnd = Read-Host 'Weekend end time HH:mm (blank = weekday end)'
        $groupInput = Read-Host 'Assigned group IDs, comma-separated (optional)'

        $groupIds = @(
            if (-not [string]::IsNullOrWhiteSpace($groupInput)) {
                $groupInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
        )

        $createParams = @{
            DisplayName                   = $displayName
            Description                   = $description
            NotificationLeadTimeInMinutes = $lead
            WeekdayStartTime              = $weekdayStart
            WeekdayEndTime                = $weekdayEnd
            GroupId                       = $groupIds
        }
        if (-not [string]::IsNullOrWhiteSpace($weekendStart)) {
            $createParams.WeekendStartTime = $weekendStart
        }
        if (-not [string]::IsNullOrWhiteSpace($weekendEnd)) {
            $createParams.WeekendEndTime = $weekendEnd
        }

        Invoke-W365CloudPCConfirmedAction -CloudPC ([pscustomobject]@{
            Name = $displayName
        }) -ActionName 'Create' -TargetType 'maintenance window' -Context @{
            Params = $createParams
        } -PreviewScript {
            param($Target, $Context)

            $params = $Context.Params
            New-CloudPCMaintenanceWindow @params -WhatIf
        } -SubmitScript {
            param($Target, $Context)

            $params = $Context.Params
            New-CloudPCMaintenanceWindow @params -Force
        }
    }

    end { }
}
