function Show-W365OrganizationSetting {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.OrganizationSetting')]
    param(
        [switch]$Browse
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $items = @(Get-CloudPCOrganizationSetting)
        if ($items.Count -eq 0) {
            Write-Warning 'No organization settings were returned.'
            return
        }

        Select-W365CliObject -InputObject $items -Title 'Windows 365 organization settings' -DisplayProperties @(
            'OsVersion',
            'UserAccountType',
            'MEMAutoEnrollEnabled',
            'SingleSignOnEnabled',
            'WindowsLanguage'
        ) -FilterProperties @(
            'OsVersion',
            'UserAccountType',
            'WindowsLanguage'
        ) -LabelScript {
            param($Setting)

            'OS: {0} | User: {1} | MEM auto-enroll: {2} | SSO: {3} | Language: {4}' -f
                $Setting.OsVersion,
                $Setting.UserAccountType,
                $Setting.MEMAutoEnrollEnabled,
                $Setting.SingleSignOnEnabled,
                $Setting.WindowsLanguage
        } -DetailScript {
            param($Setting)

            @(
                "Default OS version:       $($Setting.OsVersion)"
                "Default user account:     $($Setting.UserAccountType)"
                "MEM auto-enroll:          $($Setting.MEMAutoEnrollEnabled)"
                "Single sign-on:           $($Setting.SingleSignOnEnabled)"
                "Windows language:         $($Setting.WindowsLanguage)"
                "Organization setting ID:  $($Setting.Id)"
            )
        } -ActionScript {
            param($Setting, $Action)
            if ($Action -ne 'Update settings') { return }
            $osChoice = Read-W365CliChoice -Prompt 'Default OS version' -Choices @('Keep current','Windows 11','Windows 10') -AllowBack
            if ($osChoice -lt 0) { return }
            $accountChoice = Read-W365CliChoice -Prompt 'Default user account type' -Choices @('Keep current','Standard user','Administrator') -AllowBack
            if ($accountChoice -lt 0) { return }
            $memChoice = Read-W365CliChoice -Prompt 'MEM auto-enrollment' -Choices @('Keep current','Enabled','Disabled') -AllowBack
            if ($memChoice -lt 0) { return }
            $ssoChoice = Read-W365CliChoice -Prompt 'Single sign-on' -Choices @('Keep current','Enabled','Disabled') -AllowBack
            if ($ssoChoice -lt 0) { return }
            $language = Read-Host "Windows language [$($Setting.WindowsLanguage)]"
            $params = @{ PassThru = $true }
            if ($osChoice -eq 1) { $params.OsVersion = 'windows11' } elseif ($osChoice -eq 2) { $params.OsVersion = 'windows10' }
            if ($accountChoice -eq 1) { $params.UserAccountType = 'standardUser' } elseif ($accountChoice -eq 2) { $params.UserAccountType = 'administrator' }
            if ($memChoice -eq 1) { $params.EnableMEMAutoEnroll = $true } elseif ($memChoice -eq 2) { $params.EnableMEMAutoEnroll = $false }
            if ($ssoChoice -eq 1) { $params.EnableSingleSignOn = $true } elseif ($ssoChoice -eq 2) { $params.EnableSingleSignOn = $false }
            if (-not [string]::IsNullOrWhiteSpace($language)) { $params.WindowsLanguage = $language }
            if ($params.Count -eq 1) {
                Write-Warning 'No setting changes selected.'
                [Console]::ReadKey($true) | Out-Null
                return
            }
            Invoke-W365CloudPCConfirmedAction -CloudPC ([pscustomobject]@{ Name = 'Windows 365 organization settings' }) -ActionName 'Update' -TargetType 'organization settings' -Context @{ Params = $params } -PreviewScript {
                param($Target, $Context)
                $updateParams = $Context.Params
                Update-CloudPCOrganizationSetting @updateParams -WhatIf
            } -SubmitScript {
                param($Target, $Context)
                $updateParams = $Context.Params
                Update-CloudPCOrganizationSetting @updateParams -Force
            }
        } -ActionLabels @(
            'Update settings'
        ) -SummaryScript {
            param(
                [object[]]$AllItems,
                [object[]]$VisibleItems,
                [string]$Filter,
                [int]$SelectedIndex
            )

            @(
                "Total: $($AllItems.Count) | Visible: $($VisibleItems.Count)"
                $(if ($Filter) { "Search: $Filter" } else { 'Search: none' })
            )
        } -RefreshScript {
            @(Get-CloudPCOrganizationSetting)
        } -PageSize 3 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Tenant settings','Organization settings')
    }

    end { }
}
