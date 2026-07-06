function Invoke-W365CloudPCAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CloudPC,

        [string]$Action
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $actionToRun = if ($Action) { $Action } else { 'Back' }

        switch ($actionToRun) {
            'Remote action history' {
                    Show-W365CloudPCRemoteActionHistory -CloudPC $CloudPC
            }
            'Disk space utilization' {
                    Show-W365DiskSpace -CloudPC $CloudPC -Browse | Out-Null
            }
            'Resize' {
                    Invoke-W365Resize -CloudPC $CloudPC
            }
            'Power on' {
                    Invoke-W365CloudPCConfirmedAction -CloudPC $CloudPC -ActionName 'Power on' -PreviewScript {
                        param($TargetCloudPC, $Context)

                        $TargetCloudPC | Start-CloudPC -PassThru -WhatIf
                    } -SubmitScript {
                        param($TargetCloudPC, $Context)

                        $TargetCloudPC | Start-CloudPC -PassThru -Force
                    } -OfferRemoteActionHistory
            }
            'Rename' {
                    $newDisplayName = Read-Host 'New Cloud PC display name'
                    if ([string]::IsNullOrWhiteSpace($newDisplayName)) {
                        Write-Warning 'Rename cancelled. New display name is required.'
                        Write-Host 'Press any key to continue...' -ForegroundColor DarkGray
                        [Console]::ReadKey($true) | Out-Null
                        return
                    }

                    $managedDeviceChoice = Read-W365CliChoice -Prompt 'Also rename the Intune managed device?' -Choices @(
                        'No',
                        'Yes, use the same name',
                        'Yes, enter a different managed device name'
                    ) -AllowBack
                    if ($managedDeviceChoice -lt 0) {
                        return
                    }

                    $renameParams = @{
                        CloudPC        = $CloudPC
                        NewDisplayName = $newDisplayName
                        PassThru       = $true
                    }

                    if ($managedDeviceChoice -eq 1) {
                        $renameParams.ManagedDeviceName = $newDisplayName
                    }
                    elseif ($managedDeviceChoice -eq 2) {
                        $managedDeviceName = Read-Host 'New managed device name'
                        if ([string]::IsNullOrWhiteSpace($managedDeviceName)) {
                            Write-Warning 'Rename cancelled. Managed device name is required for this option.'
                            Write-Host 'Press any key to continue...' -ForegroundColor DarkGray
                            [Console]::ReadKey($true) | Out-Null
                            return
                        }

                        $renameParams.ManagedDeviceName = $managedDeviceName
                    }

                    Invoke-W365CloudPCConfirmedAction -CloudPC $CloudPC -ActionName 'Rename' -Context @{
                        Params = $renameParams
                    } -PreviewScript {
                        param($TargetCloudPC, $Context)

                        $params = $Context.Params
                        Rename-CloudPC @params -WhatIf
                    } -SubmitScript {
                        param($TargetCloudPC, $Context)

                        $params = $Context.Params
                        Rename-CloudPC @params -Force
                    } -OfferRemoteActionHistory
            }
            'Sync' {
                    Invoke-W365CloudPCConfirmedAction -CloudPC $CloudPC -ActionName 'Sync' -PreviewScript {
                        param($TargetCloudPC, $Context)

                        $TargetCloudPC | Sync-CloudPC -PassThru -WhatIf
                    } -SubmitScript {
                        param($TargetCloudPC, $Context)

                        $TargetCloudPC | Sync-CloudPC -PassThru -Force
                    } -OfferRemoteActionHistory
            }
            'Reset local admin password' {
                    Invoke-W365CloudPCConfirmedAction -CloudPC $CloudPC -ActionName 'Reset local admin password' -PreviewScript {
                        param($TargetCloudPC, $Context)

                        $TargetCloudPC | Reset-CloudPCLocalAdminPassword -PassThru -WhatIf
                    } -SubmitScript {
                        param($TargetCloudPC, $Context)

                        $TargetCloudPC | Reset-CloudPCLocalAdminPassword -PassThru -Force
                    } -OfferRemoteActionHistory
            }
            'Restart' {
                    Invoke-W365CloudPCConfirmedAction -CloudPC $CloudPC -ActionName 'Restart' -PreviewScript {
                        param($TargetCloudPC, $Context)

                        $TargetCloudPC | Restart-CloudPC -PassThru -WhatIf
                    } -SubmitScript {
                        param($TargetCloudPC, $Context)

                        $TargetCloudPC | Restart-CloudPC -PassThru -Force
                    } -OfferRemoteActionHistory
            }
            'Snapshots' {
                    Show-W365Snapshot -CloudPC $CloudPC -Browse | Out-Null
            }
            'Reprovision' {
                    $osChoice = Read-W365CliChoice -Prompt 'Reprovision OS version' -Choices @(
                        'Keep policy/default',
                        'Windows 11',
                        'Windows 10'
                    ) -AllowBack
                    if ($osChoice -lt 0) {
                        return
                    }

                    $accountChoice = Read-W365CliChoice -Prompt 'Reprovision user account type' -Choices @(
                        'Keep policy/default',
                        'Standard user',
                        'Administrator'
                    ) -AllowBack
                    if ($accountChoice -lt 0) {
                        return
                    }

                    $reprovisionParams = @{
                        CloudPC  = $CloudPC
                        PassThru = $true
                    }
                    if ($osChoice -eq 1) {
                        $reprovisionParams.OsVersion = 'windows11'
                    }
                    elseif ($osChoice -eq 2) {
                        $reprovisionParams.OsVersion = 'windows10'
                    }

                    if ($accountChoice -eq 1) {
                        $reprovisionParams.UserAccountType = 'standardUser'
                    }
                    elseif ($accountChoice -eq 2) {
                        $reprovisionParams.UserAccountType = 'administrator'
                    }

                    Invoke-W365CloudPCConfirmedAction -CloudPC $CloudPC -ActionName 'Reprovision' -Context @{
                        Params = $reprovisionParams
                    } -PreviewScript {
                        param($TargetCloudPC, $Context)

                        $params = $Context.Params
                        Invoke-CloudPCReprovision @params -WhatIf
                    } -SubmitScript {
                        param($TargetCloudPC, $Context)

                        $params = $Context.Params
                        Invoke-CloudPCReprovision @params -Force
                    } -OfferRemoteActionHistory
            }
            'End grace period' {
                    Invoke-W365CloudPCConfirmedAction -CloudPC $CloudPC -ActionName 'End grace period' -PreviewScript {
                        param($TargetCloudPC, $Context)

                        $TargetCloudPC | Invoke-CloudPCEndGracePeriod -PassThru -WhatIf
                    } -SubmitScript {
                        param($TargetCloudPC, $Context)

                        $TargetCloudPC | Invoke-CloudPCEndGracePeriod -PassThru -Force
                    } -OfferRemoteActionHistory
            }
            default {
                return
            }
        }
    }

    end { }
}
