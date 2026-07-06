function Get-W365UsageData {
    [CmdletBinding()]
    param()

    begin { }

    process {
        $previousProgressPreference = $ProgressPreference
        try {
            $ProgressPreference = 'SilentlyContinue'
            Get-CloudPCUsage -ProgressAction SilentlyContinue | Sort-Object UsageStatus, CloudPcName
        }
        finally {
            $ProgressPreference = $previousProgressPreference
        }
    }

    end { }
}
