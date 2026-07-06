function Invoke-W365ProvisioningPolicyAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Policy,

        [string]$Action
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        switch ($Action) {
            'View Cloud PCs' {
                $cloudPcs = @(Get-CloudPC -ProvisioningPolicyId $Policy.Id | Sort-Object Name)
                if ($cloudPcs.Count -eq 0) {
                    Write-Warning 'No Cloud PCs were returned for this provisioning policy.'
                    Write-Host 'Press any key to continue...' -ForegroundColor DarkGray
                    [Console]::ReadKey($true) | Out-Null
                    return
                }

                Select-W365CliObject -InputObject $cloudPcs -Title "Cloud PCs in $($Policy.DisplayName)" -DisplayProperties @(
                    'Name',
                    'AssignedUserUpn',
                    'ProvisioningType',
                    'ProvisioningStatus',
                    'ServicePlanName'
                ) -FilterProperties @(
                    'Name',
                    'ManagedDeviceName',
                    'AssignedUserUpn',
                    'ProvisioningType',
                    'ProvisioningStatus',
                    'ServicePlanName'
                ) -LabelScript {
                    param($CloudPC)

                    '{0} {1} {2} {3} {4}' -f
                        (Format-W365CliText -Text $CloudPC.Name -Width 34),
                        (Format-W365CliText -Text $CloudPC.AssignedUserUpn -Width 34),
                        (Format-W365CliText -Text $CloudPC.ProvisioningType -Width 10),
                        (Format-W365CliText -Text $CloudPC.ProvisioningStatus -Width 14),
                        (Format-W365CliText -Text $CloudPC.ServicePlanName -Width 40)
                } -DetailScript {
                    param($CloudPC)

                    @(
                        "Name:                 $($CloudPC.Name)"
                        "Managed device name:  $($CloudPC.ManagedDeviceName)"
                        "Assigned user:        $($CloudPC.AssignedUserUpn)"
                        "Provisioning type:    $($CloudPC.ProvisioningType)"
                        "Provisioning status:  $($CloudPC.ProvisioningStatus)"
                        "Service plan:         $($CloudPC.ServicePlanName)"
                        "Cloud PC ID:          $($CloudPC.Id)"
                        "Managed device ID:    $($CloudPC.ManagedDeviceId)"
                        "Entra device ID:      $($CloudPC.AadDeviceId)"
                    )
                } -ActionScript {
                    param($CloudPC, $Action)

                    Invoke-W365CloudPCAction -CloudPC $CloudPC -Action $Action
                } -ActionLabelsScript {
                    param($CloudPC)

                    Get-W365CloudPCActionItem -CloudPC $CloudPC
                } -SummaryScript {
                    param(
                        [object[]]$AllItems,
                        [object[]]$VisibleItems,
                        [string]$Filter,
                        [int]$SelectedIndex
                    )

                    Get-W365CloudPCSummary -AllItems $AllItems -VisibleItems $VisibleItems -Filter $Filter -SelectedIndex $SelectedIndex
                } -ColumnHeader ('{0} {1} {2} {3} {4}' -f
                    (Format-W365CliText -Text 'Name' -Width 34),
                    (Format-W365CliText -Text 'Assigned user' -Width 34),
                    (Format-W365CliText -Text 'Type' -Width 10),
                    (Format-W365CliText -Text 'Status' -Width 14),
                    (Format-W365CliText -Text 'Service plan' -Width 40)
                ) -RefreshScript {
                    @(Get-CloudPC -ProvisioningPolicyId $Policy.Id | Sort-Object Name)
                } -PageSize 18 -ViewOnly -Breadcrumb @('W365CLI','Provisioning','Provisioning policies','Cloud PCs') | Out-Null
            }
            'Export' {
                $defaultPath = Join-Path -Path (Get-Location) -ChildPath ("{0}.json" -f ($Policy.DisplayName -replace '[\\/:*?"<>|]', '-'))
                $path = Read-Host "Export path [$defaultPath]"
                if ([string]::IsNullOrWhiteSpace($path)) {
                    $path = $defaultPath
                }

                $Policy | Export-CloudPCProvisioningPolicy -Path $path -Force
                Write-Host ''
                Write-Host "Exported to $path" -ForegroundColor Green
                Write-Host 'Press any key to continue...' -ForegroundColor DarkGray
                [Console]::ReadKey($true) | Out-Null
            }
            'Create copy' {
                $displayName = Read-Host 'New policy display name'
                if ([string]::IsNullOrWhiteSpace($displayName)) {
                    Write-Warning 'Create copy cancelled. Display name is required.'
                    Write-Host 'Press any key to continue...' -ForegroundColor DarkGray
                    [Console]::ReadKey($true) | Out-Null
                    return
                }

                $assignChoice = Read-W365CliChoice -Prompt 'Recreate assignment targets on the new policy?' -Choices @(
                    'No',
                    'Yes'
                ) -AllowBack
                if ($assignChoice -lt 0) {
                    return
                }

                $export = $Policy | Export-CloudPCProvisioningPolicy
                $createParams = @{
                    InputObject = $export
                    DisplayName = $displayName
                }
                if ($assignChoice -eq 1) {
                    $createParams.Assign = $true
                }

                Invoke-W365CloudPCConfirmedAction -CloudPC ([pscustomobject]@{
                    Name            = $Policy.DisplayName
                    AssignedUserUpn = ''
                }) -ActionName 'Create' -TargetType 'provisioning policy copy' -Context @{
                    Params = $createParams
                } -PreviewScript {
                    param($Target, $Context)

                    $params = $Context.Params
                    New-CloudPCProvisioningPolicy @params -WhatIf
                } -SubmitScript {
                    param($Target, $Context)

                    $params = $Context.Params
                    New-CloudPCProvisioningPolicy @params -Force
                }
            }
            'Delete' {
                Invoke-W365CloudPCConfirmedAction -CloudPC ([pscustomobject]@{
                    Name            = $Policy.DisplayName
                    AssignedUserUpn = ''
                }) -ActionName 'Delete' -TargetType 'provisioning policy' -Context @{
                    Policy = $Policy
                } -PreviewScript {
                    param($Target, $Context)

                    $Context.Policy | Remove-CloudPCProvisioningPolicy -PassThru -WhatIf
                } -SubmitScript {
                    param($Target, $Context)

                    $Context.Policy | Remove-CloudPCProvisioningPolicy -PassThru -Force
                }
            }
            'Reprovision policy Cloud PCs' {
                $osChoice = Read-W365CliChoice -Prompt 'Policy reprovision OS version' -Choices @('Keep policy/default','Windows 11','Windows 10') -AllowBack
                if ($osChoice -lt 0) { return }
                $accountChoice = Read-W365CliChoice -Prompt 'Policy reprovision user account type' -Choices @('Keep policy/default','Standard user','Administrator') -AllowBack
                if ($accountChoice -lt 0) { return }
                $excludeInput = Read-Host 'Exclude Cloud PCs by name, ID, or UPN (comma-separated, optional)'
                $params = @{ ProvisioningPolicyId = $Policy.Id }
                if ($osChoice -eq 1) { $params.OsVersion = 'windows11' }
                elseif ($osChoice -eq 2) { $params.OsVersion = 'windows10' }
                if ($accountChoice -eq 1) { $params.UserAccountType = 'standardUser' }
                elseif ($accountChoice -eq 2) { $params.UserAccountType = 'administrator' }
                if (-not [string]::IsNullOrWhiteSpace($excludeInput)) {
                    $params.ExcludeCloudPC = @($excludeInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                }
                Invoke-W365CloudPCConfirmedAction -CloudPC ([pscustomobject]@{ Name = $Policy.DisplayName }) -ActionName 'Reprovision' -TargetType 'policy Cloud PCs' -Context @{ Params = $params } -PreviewScript {
                    param($Target, $Context)
                    $invokeParams = $Context.Params
                    Invoke-CloudPCPolicyReprovision @invokeParams -WhatIf
                } -SubmitScript {
                    param($Target, $Context)
                    $invokeParams = $Context.Params
                    Invoke-CloudPCPolicyReprovision @invokeParams -Force
                }
            }
            default {
                return
            }
        }
    }

    end { }
}
