function Show-W365LicensingAllotment {
    [CmdletBinding()]
    [OutputType('WindowsCloudPC.LicensingAllotment')]
    param([switch]$Browse)

    begin { Import-W365CliWindowsCloudPC }

    process {
        $items = @(Get-CloudPCLicensingAllotment | Sort-Object SkuPartNumber)
        if ($items.Count -eq 0) { Write-Warning 'No licensing allotments were returned.'; return }
        $columnHeader = '{0} {1} {2} {3} {4} {5}' -f (Format-W365CliText -Text 'SKU' -Width 34),(Format-W365CliText -Text 'Allotted' -Width 10),(Format-W365CliText -Text 'Consumed' -Width 10),(Format-W365CliText -Text 'Available' -Width 10),(Format-W365CliText -Text 'Waiting' -Width 9),(Format-W365CliText -Text 'Assignable' -Width 18)
        Select-W365CliObject -InputObject $items -Title 'Windows 365 licensing allotments' -DisplayProperties @('SkuPartNumber','AllottedUnits','ConsumedUnits','AvailableUnits','WaitingMemberCount','AssignableTo') -FilterProperties @('SkuPartNumber','AssignableTo','ServicePlanNames') -LabelScript {
            param($Allotment)
            '{0} {1} {2} {3} {4} {5}' -f (Format-W365CliText -Text $Allotment.SkuPartNumber -Width 34),(Format-W365CliText -Text $Allotment.AllottedUnits -Width 10),(Format-W365CliText -Text $Allotment.ConsumedUnits -Width 10),(Format-W365CliText -Text $Allotment.AvailableUnits -Width 10),(Format-W365CliText -Text $Allotment.WaitingMemberCount -Width 9),(Format-W365CliText -Text $Allotment.AssignableTo -Width 18)
        } -DetailScript {
            param($Allotment)
            @("SKU: $($Allotment.SkuPartNumber)","SKU ID: $($Allotment.SkuId)","Allotted: $($Allotment.AllottedUnits)","Consumed: $($Allotment.ConsumedUnits)","Available: $($Allotment.AvailableUnits)","Assignable to: $($Allotment.AssignableTo)","Services: $($Allotment.ServicePlanNames -join ', ')","Subscriptions: $($Allotment.SubscriptionIds -join ', ')","Waiting members: $($Allotment.WaitingMemberCount)","Allotment ID: $($Allotment.Id)")
        } -RefreshScript {
            @(Get-CloudPCLicensingAllotment | Sort-Object SkuPartNumber)
        } -ColumnHeader $columnHeader -PageSize 18 -ViewOnly:$Browse -Breadcrumb @('W365CLI','Catalog','Licensing allotments')
    }
}
