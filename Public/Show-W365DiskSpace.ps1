function Show-W365DiskSpace {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.CloudPCDiskSpace')]
    param(
        [object]$CloudPC,

        [switch]$Browse
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $loadMessage = if ($PSBoundParameters.ContainsKey('CloudPC')) {
            "Loading disk space for $($CloudPC.Name)."
        }
        else {
            'Loading Cloud PC disk space. This can take a while because Intune disk inventory is queried per Cloud PC.'
        }

        $items = @(Invoke-W365CliSpinner -Message $loadMessage -ArgumentList @($CloudPC) -ScriptBlock {
            param($TargetCloudPC)

            if ($TargetCloudPC) {
                $TargetCloudPC | Get-CloudPCDiskSpace
            }
            else {
                Get-CloudPCDiskSpace | Sort-Object PercentFree, CloudPcName
            }
        })
        if ($items.Count -eq 0) {
            Write-Warning 'No Cloud PC disk space records were returned.'
            return
        }

        $title = if ($PSBoundParameters.ContainsKey('CloudPC')) {
            "Disk space for $($CloudPC.Name)"
        }
        elseif ($Browse) {
            'Windows 365 Cloud PC disk space'
        }
        else {
            'Pick a Cloud PC disk space record'
        }
        $columnHeader = '{0} {1} {2} {3} {4} {5} {6}' -f
            (Format-W365CliText -Text 'Cloud PC' -Width 34),
            (Format-W365CliText -Text 'User' -Width 34),
            (Format-W365CliText -Text 'Free' -Width 9),
            (Format-W365CliText -Text 'Used' -Width 9),
            (Format-W365CliText -Text 'Total' -Width 9),
            (Format-W365CliText -Text 'Free %' -Width 8),
            (Format-W365CliText -Text 'Last sync' -Width 22)

        Select-W365CliObject -InputObject $items -Title $title -DisplayProperties @(
            'CloudPcName',
            'AssignedUserUpn',
            'FreeStorageGB',
            'UsedStorageGB',
            'TotalStorageGB',
            'PercentFree',
            'LastSyncDateTime'
        ) -FilterProperties @(
            'CloudPcName',
            'ManagedDeviceName',
            'AssignedUserUpn',
            'ProvisioningType',
            'ProvisioningPolicyName'
        ) -LabelScript {
            param($Disk)

            '{0} {1} {2} {3} {4} {5} {6}' -f
                (Format-W365CliText -Text $Disk.CloudPcName -Width 34),
                (Format-W365CliText -Text $Disk.AssignedUserUpn -Width 34),
                (Format-W365CliText -Text "$($Disk.FreeStorageGB) GB" -Width 9),
                (Format-W365CliText -Text "$($Disk.UsedStorageGB) GB" -Width 9),
                (Format-W365CliText -Text "$($Disk.TotalStorageGB) GB" -Width 9),
                (Format-W365CliText -Text "$($Disk.PercentFree)%" -Width 8),
                (Format-W365CliText -Text $Disk.LastSyncDateTime -Width 22)
        } -DetailScript {
            param($Disk)

            @(
                "Cloud PC:              $($Disk.CloudPcName)"
                "Managed device:        $($Disk.ManagedDeviceName)"
                "Assigned user:         $($Disk.AssignedUserUpn)"
                "Provisioning type:     $($Disk.ProvisioningType)"
                "Provisioning policy:   $($Disk.ProvisioningPolicyName)"
                "Total storage:         $($Disk.TotalStorageGB) GB"
                "Free storage:          $($Disk.FreeStorageGB) GB"
                "Used storage:          $($Disk.UsedStorageGB) GB"
                "Percent free:          $($Disk.PercentFree)%"
                "Percent used:          $($Disk.PercentUsed)%"
                "Last sync:             $($Disk.LastSyncDateTime)"
                "Cloud PC ID:           $($Disk.CloudPcId)"
                "Managed device ID:     $($Disk.ManagedDeviceId)"
            )
        } -SummaryScript {
            param(
                [object[]]$AllItems,
                [object[]]$VisibleItems,
                [string]$Filter,
                [int]$SelectedIndex
            )

            $lowCount = @($AllItems | Where-Object { $null -ne $_.PercentFree -and $_.PercentFree -lt 15 }).Count
            $criticalCount = @($AllItems | Where-Object { $null -ne $_.PercentFree -and $_.PercentFree -lt 5 }).Count
            $averageFree = if ($AllItems.Count -gt 0) {
                [math]::Round((($AllItems | Where-Object { $null -ne $_.PercentFree } | Measure-Object -Property PercentFree -Average).Average), 1)
            }
            else {
                $null
            }

            @(
                "Total: $($AllItems.Count) | Visible: $($VisibleItems.Count) | Selected: $([math]::Min($SelectedIndex + 1, [math]::Max($VisibleItems.Count, 1)))"
                "Low free <15%: $lowCount | Critical <5%: $criticalCount | Average free: $averageFree%"
                $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
            )
        } -RefreshScript {
            @(Invoke-W365CliSpinner -Message "Refreshing $title." -ArgumentList @($CloudPC) -ScriptBlock {
                param($TargetCloudPC)

                if ($TargetCloudPC) {
                    $TargetCloudPC | Get-CloudPCDiskSpace
                }
                else {
                    Get-CloudPCDiskSpace | Sort-Object PercentFree, CloudPcName
                }
            })
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Cloud PCs','Disk space')
    }

    end { }
}
