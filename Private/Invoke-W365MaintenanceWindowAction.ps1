function Invoke-W365MaintenanceWindowAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$MaintenanceWindow,

        [string]$Action
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        switch ($Action) {
            'View assigned group members' {
                $assignments = @($MaintenanceWindow.Assignments | Where-Object { $_.GroupId })
                if ($assignments.Count -eq 0) {
                    Write-Warning 'This maintenance window has no assigned groups.'
                    Write-Host 'Press any key to continue...' -ForegroundColor DarkGray
                    [Console]::ReadKey($true) | Out-Null
                    return
                }

                $group = Select-W365CliObject -InputObject $assignments -Title "Assigned groups for $($MaintenanceWindow.DisplayName)" -DisplayProperties @(
                    'GroupName',
                    'GroupId',
                    'TargetType'
                ) -FilterProperties @(
                    'GroupName',
                    'GroupId',
                    'TargetType'
                ) -LabelScript {
                    param($Assignment)

                    '{0} {1}' -f
                        (Format-W365CliText -Text $Assignment.GroupName -Width 46),
                        (Format-W365CliText -Text $Assignment.GroupId -Width 38)
                } -DetailScript {
                    param($Assignment)

                    @(
                        "Group name:  $($Assignment.GroupName)"
                        "Group ID:    $($Assignment.GroupId)"
                        "Target type: $($Assignment.TargetType)"
                    )
                } -ColumnHeader ('{0} {1}' -f
                    (Format-W365CliText -Text 'Group name' -Width 46),
                    (Format-W365CliText -Text 'Group ID' -Width 38)
                ) -PageSize 12 -Breadcrumb @('W365CLI','Provisioning','Maintenance windows','Assigned groups')

                if ($group) {
                    Show-W365GroupMember -GroupId $group.GroupId -GroupName $group.GroupName
                }
            }
            'Edit' {
                $displayName = Read-Host "Display name [$($MaintenanceWindow.DisplayName)]"
                $description = Read-Host "Description [$($MaintenanceWindow.Description)]"
                $leadInput = Read-Host "Notification lead time in minutes [$($MaintenanceWindow.NotificationLeadTimeInMinutes)]"
                $weekdayStart = Read-Host 'Weekday start time HH:mm (blank = keep current)'
                $weekdayEnd = Read-Host 'Weekday end time HH:mm (blank = keep current)'
                $weekendStart = Read-Host 'Weekend start time HH:mm (blank = keep current)'
                $weekendEnd = Read-Host 'Weekend end time HH:mm (blank = keep current)'

                $body = [ordered]@{
                    displayName                   = if ([string]::IsNullOrWhiteSpace($displayName)) { $MaintenanceWindow.DisplayName } else { $displayName }
                    description                   = if ([string]::IsNullOrWhiteSpace($description)) { $MaintenanceWindow.Description } else { $description }
                    notificationLeadTimeInMinutes = if ([string]::IsNullOrWhiteSpace($leadInput)) { $MaintenanceWindow.NotificationLeadTimeInMinutes } else { [int]$leadInput }
                }

                $currentSchedules = @($MaintenanceWindow.Schedules)
                $weekday = $currentSchedules | Where-Object { $_.scheduleType -eq 'weekday' } | Select-Object -First 1
                $weekend = $currentSchedules | Where-Object { $_.scheduleType -eq 'weekend' } | Select-Object -First 1
                if (-not $weekdayStart -and -not $weekdayEnd -and -not $weekendStart -and -not $weekendEnd) {
                    $body.schedules = $currentSchedules
                }
                else {
                    $body.schedules = @(
                        @{
                            scheduleType = 'weekday'
                            startTime    = if ($weekdayStart) { "${weekdayStart}:00.000" } else { $weekday.startTime }
                            endTime      = if ($weekdayEnd) { "${weekdayEnd}:00.000" } else { $weekday.endTime }
                        }
                        @{
                            scheduleType = 'weekend'
                            startTime    = if ($weekendStart) { "${weekendStart}:00.000" } else { $weekend.startTime }
                            endTime      = if ($weekendEnd) { "${weekendEnd}:00.000" } else { $weekend.endTime }
                        }
                    )
                }

                Invoke-W365CloudPCConfirmedAction -CloudPC ([pscustomobject]@{
                    Name = $MaintenanceWindow.DisplayName
                }) -ActionName 'Edit' -TargetType 'maintenance window' -Context @{
                    Id   = $MaintenanceWindow.Id
                    Body = $body
                } -PreviewScript {
                    param($Target, $Context)

                    [pscustomobject]@{
                        Id      = $Context.Id
                        Preview = ($Context.Body | ConvertTo-Json -Depth 10)
                    }
                } -SubmitScript {
                    param($Target, $Context)

                    Connect-CloudPC -AdditionalScopes 'CloudPC.ReadWrite.All' | Out-Null
                    $escapedId = [uri]::EscapeDataString($Context.Id)
                    $uri = "https://graph.microsoft.com/beta/deviceManagement/virtualEndpoint/maintenanceWindows/$escapedId"
                    Invoke-MgGraphRequest -Method PATCH -Uri $uri -ContentType 'application/json' -Body ($Context.Body | ConvertTo-Json -Depth 20 -Compress)
                    Write-Host 'Maintenance window update submitted.' -ForegroundColor Green
                }
            }
            'Delete' {
                Invoke-W365CloudPCConfirmedAction -CloudPC ([pscustomobject]@{
                    Name = $MaintenanceWindow.DisplayName
                }) -ActionName 'Delete' -TargetType 'maintenance window' -Context @{
                    Window = $MaintenanceWindow
                } -PreviewScript {
                    param($Target, $Context)

                    $Context.Window | Remove-CloudPCMaintenanceWindow -PassThru -WhatIf
                } -SubmitScript {
                    param($Target, $Context)

                    $Context.Window | Remove-CloudPCMaintenanceWindow -PassThru -Force
                }
            }
            default {
                return
            }
        }
    }

    end { }
}
