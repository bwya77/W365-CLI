function Show-W365CloudPC {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.CloudPC')]
    param(
        [switch]$Browse
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $cloudPcs = @(Get-CloudPC | Sort-Object Name)
        if ($cloudPcs.Count -eq 0) {
            Write-Warning 'No Cloud PCs were returned.'
            return
        }

        $browserTitle = if ($Browse) { 'Windows 365 Cloud PCs' } else { 'Pick a Windows 365 Cloud PC' }
        $columnHeader = '{0} {1} {2} {3} {4}' -f
            (Format-W365CliText -Text 'Name' -Width 34),
            (Format-W365CliText -Text 'Assigned user' -Width 34),
            (Format-W365CliText -Text 'Type' -Width 10),
            (Format-W365CliText -Text 'Status' -Width 14),
            (Format-W365CliText -Text 'Service plan' -Width 40)

        Select-W365CliObject -InputObject $cloudPcs -Title $browserTitle -DisplayProperties @(
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
        } -DetailProperties @(
            'Name',
            'ManagedDeviceName',
            'AssignedUserUpn',
            'UserPrincipalName',
            'ProvisioningType',
            'ProvisioningStatus',
            'ServicePlanName',
            'ManagedDeviceId',
            'AadDeviceId',
            'Id'
        ) -DetailScript {
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
        } -RefreshScript {
            @(Get-CloudPC | Sort-Object Name)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Cloud PCs','Browse and manage')
    }

    end { }
}
