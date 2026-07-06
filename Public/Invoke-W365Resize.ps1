function Invoke-W365Resize {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.ResizeResult')]
    param(
        [object]$CloudPC,

        [switch]$UseMaintenanceWindow
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $cloudPc = if ($PSBoundParameters.ContainsKey('CloudPC')) {
            $CloudPC
        }
        else {
            Show-W365CloudPC
        }

        if (-not $cloudPc) {
            return
        }

        $plan = Show-W365ServicePlan
        if (-not $plan) {
            return
        }

        Write-Host ''
        Write-Host 'Resize preview' -ForegroundColor Cyan
        Write-Host ("Cloud PC:     {0}" -f $cloudPc.Name)
        Write-Host ("User:         {0}" -f $cloudPc.AssignedUserUpn)
        Write-Host ("Target plan:  {0}" -f $plan.DisplayName)
        Write-Host ("Plan shape:   {0} vCPU, {1} GB RAM, {2} GB storage" -f $plan.VCpuCount, $plan.RamGB, $plan.StorageGB)

        $choice = Read-W365CliChoice -Prompt 'Choose resize action' -Choices @(
            'Preview only with -WhatIf',
            'Resize now',
            'Cancel'
        )

        switch ($choice) {
            0 {
                $resizeParams = @{
                    TargetServicePlan = $plan
                    PassThru          = $true
                    WhatIf            = $true
                }
                if ($UseMaintenanceWindow) {
                    $resizeParams.UseMaintenanceWindow = $true
                }

                $cloudPc | Resize-CloudPC @resizeParams

                $historyChoice = Read-W365CliChoice -Prompt 'Check remote action history now?' -Choices @(
                    'Yes',
                    'No'
                ) -AllowBack

                if ($historyChoice -eq 0) {
                    Show-W365CloudPCRemoteActionHistory -CloudPC $cloudPc
                }
            }
            1 {
                $confirmChoice = Read-W365CliChoice -Prompt 'Submit resize request now?' -Choices @(
                    'Confirm',
                    'Cancel'
                ) -AllowBack

                if ($confirmChoice -ne 0) {
                    Write-Warning 'Resize cancelled.'
                    return
                }

                $resizeParams = @{
                    TargetServicePlan = $plan
                    PassThru          = $true
                    Force             = $true
                }
                if ($UseMaintenanceWindow) {
                    $resizeParams.UseMaintenanceWindow = $true
                }

                $cloudPc | Resize-CloudPC @resizeParams
            }
            default {
                Write-Host 'Resize cancelled.'
            }
        }
    }

    end { }
}
