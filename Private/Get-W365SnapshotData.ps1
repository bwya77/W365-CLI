function Get-W365SnapshotData {
    [CmdletBinding()]
    param(
        [object]$CloudPC
    )

    begin {
        Import-W365CliWindowsCloudPC
        Connect-CloudPC | Out-Null
    }

    process {
        $targets = if ($CloudPC) {
            @($CloudPC)
        }
        else {
            @(Get-CloudPC)
        }

        foreach ($target in $targets) {
            if (-not $target.Id) {
                continue
            }

            $cloudPcName = if ($target.Name) { $target.Name } else { $target.Id }
            $escapedCloudPcId = [uri]::EscapeDataString($target.Id)
            $select = [uri]::EscapeDataString('id,cloudPcId,status,createdDateTime,lastRestoredDateTime,snapshotType,expirationDateTime,healthCheckStatus')
            $uri = "https://graph.microsoft.com/beta/deviceManagement/virtualEndpoint/cloudPCs/$escapedCloudPcId/retrieveSnapshots?`$select=$select"

            try {
                $response = Invoke-MgGraphRequest -Method GET -Uri $uri
            }
            catch {
                Write-Warning "Snapshot lookup failed for Cloud PC '$cloudPcName' ($($target.Id)): $($_.Exception.Message)"
                continue
            }

            foreach ($snapshot in @($response.value)) {
                [pscustomobject]@{
                    PSTypeName           = 'WindowsCloudPC.Snapshot'
                    Id                   = $snapshot.id
                    SnapshotId           = $snapshot.id
                    CloudPcId            = if ($snapshot.cloudPcId) { $snapshot.cloudPcId } else { $target.Id }
                    CloudPcName          = $cloudPcName
                    Status               = $snapshot.status
                    SnapshotType         = $snapshot.snapshotType
                    CreatedDateTime      = if ($snapshot.createdDateTime) { ([datetime]$snapshot.createdDateTime).ToLocalTime() } else { $null }
                    LastRestoredDateTime = if ($snapshot.lastRestoredDateTime) { ([datetime]$snapshot.lastRestoredDateTime).ToLocalTime() } else { $null }
                    ExpirationDateTime   = if ($snapshot.expirationDateTime) { ([datetime]$snapshot.expirationDateTime).ToLocalTime() } else { $null }
                    HealthCheckStatus    = $snapshot.healthCheckStatus
                    Raw                  = $snapshot
                }
            }
        }
    }

    end { }
}
