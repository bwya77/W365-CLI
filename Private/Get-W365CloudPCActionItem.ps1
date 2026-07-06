function Get-W365CloudPCActionItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CloudPC
    )

    begin { }

    process {
        $rawPowerState = $CloudPC.Raw.powerState
        $isClearlyOff = $rawPowerState -match 'off|stopped|deallocated' -or $CloudPC.ProvisioningStatus -match 'poweredOff|stopped'
        $isInGracePeriod = $CloudPC.ProvisioningStatus -eq 'inGracePeriod'

        @(
            [pscustomobject]@{ Label = 'Remote action history'; Action = 'Remote action history'; Disabled = $false; Reason = $null }
            [pscustomobject]@{ Label = 'Disk space utilization'; Action = 'Disk space utilization'; Disabled = $false; Reason = $null }
            [pscustomobject]@{ Label = 'Snapshots'; Action = 'Snapshots'; Disabled = $false; Reason = $null }
            [pscustomobject]@{ Label = 'Resize'; Action = 'Resize'; Disabled = $false; Reason = $null }
            [pscustomobject]@{ Label = 'Power on'; Action = 'Power on'; Disabled = (-not $isClearlyOff); Reason = if ($isClearlyOff) { $null } else { 'not powered off' } }
            [pscustomobject]@{ Label = 'Rename'; Action = 'Rename'; Disabled = $false; Reason = $null }
            [pscustomobject]@{ Label = 'Sync'; Action = 'Sync'; Disabled = $false; Reason = $null }
            [pscustomobject]@{ Label = 'Restart'; Action = 'Restart'; Disabled = $false; Reason = $null }
            [pscustomobject]@{ Label = 'Reset local admin password'; Action = 'Reset local admin password'; Disabled = $false; Reason = $null }
            [pscustomobject]@{ Label = 'End grace period'; Action = 'End grace period'; Disabled = (-not $isInGracePeriod); Reason = if ($isInGracePeriod) { $null } else { 'not in grace period' } }
            [pscustomobject]@{ Label = 'Reprovision'; Action = 'Reprovision'; Disabled = $false; Reason = $null }
        )
    }

    end { }
}
