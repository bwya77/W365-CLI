function Resolve-W365CloudPCFromRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$InputObject
    )

    begin { }

    process {
        if ($InputObject.PSObject.TypeNames -contains 'WindowsCloudPC.CloudPC') {
            return $InputObject
        }

        $cloudPcId = if ($InputObject.PSObject.Properties['CloudPcId']) { $InputObject.CloudPcId } elseif ($InputObject.PSObject.Properties['Id']) { $InputObject.Id } else { $null }
        if ($cloudPcId) {
            $resolved = Get-CloudPC -Id $cloudPcId
            if ($resolved) {
                return $resolved
            }
        }

        $cloudPcName = if ($InputObject.PSObject.Properties['CloudPcName']) { $InputObject.CloudPcName } elseif ($InputObject.PSObject.Properties['Name']) { $InputObject.Name } else { $null }
        if ($cloudPcName) {
            $matches = @(Get-CloudPC -Name $cloudPcName)
            if ($matches.Count -eq 1) {
                return $matches[0]
            }
        }

        $null
    }

    end { }
}
