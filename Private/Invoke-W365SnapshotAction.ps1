function Invoke-W365SnapshotAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Snapshot,

        [string]$Action
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        switch ($Action) {
            'Create snapshot' {
                $target = if ($Snapshot.CloudPcId) {
                    [pscustomobject]@{
                        PSTypeName      = 'WindowsCloudPC.CloudPC'
                        Id              = $Snapshot.CloudPcId
                        Name            = if ($Snapshot.CloudPcName -and $Snapshot.CloudPcName -ne 'No snapshots found') { $Snapshot.CloudPcName } else { $Snapshot.CloudPcId }
                        AssignedUserUpn = $null
                    }
                }
                else {
                    Show-W365CloudPC
                }

                if (-not $target) {
                    return
                }

                Invoke-W365CloudPCConfirmedAction -CloudPC $target -ActionName 'Create snapshot' -PreviewScript {
                    param($TargetCloudPC, $Context)

                    $TargetCloudPC | New-CloudPCSnapshot -WhatIf
                } -SubmitScript {
                    param($TargetCloudPC, $Context)

                    $TargetCloudPC | New-CloudPCSnapshot -Force
                } -OfferRemoteActionHistory
            }
            'Restore Cloud PC from this snapshot' {
                if (-not $Snapshot.SnapshotId) {
                    return
                }

                $target = [pscustomobject]@{
                    PSTypeName       = 'WindowsCloudPC.CloudPC'
                    Id               = $Snapshot.CloudPcId
                    Name             = if ($Snapshot.CloudPcName) { $Snapshot.CloudPcName } else { $Snapshot.CloudPcId }
                    AssignedUserUpn  = $null
                }

                Invoke-W365CloudPCConfirmedAction -CloudPC $target -ActionName 'Restore' -Context @{
                    SnapshotId = $Snapshot.SnapshotId
                } -PreviewScript {
                    param($TargetCloudPC, $Context)

                    $TargetCloudPC | Restore-CloudPC -SnapshotId $Context.SnapshotId -PassThru -WhatIf
                } -SubmitScript {
                    param($TargetCloudPC, $Context)

                    $TargetCloudPC | Restore-CloudPC -SnapshotId $Context.SnapshotId -PassThru -Force
                } -OfferRemoteActionHistory
            }
            'Delete this snapshot' {
                if (-not $Snapshot.SnapshotId) {
                    return
                }

                $target = [pscustomobject]@{
                    Name = if ($Snapshot.CloudPcName) { "$($Snapshot.CloudPcName) snapshot $($Snapshot.SnapshotId)" } else { $Snapshot.SnapshotId }
                }

                Invoke-W365CloudPCConfirmedAction -CloudPC $target -ActionName 'Delete' -TargetType 'snapshot' -Context @{
                    SnapshotId = $Snapshot.SnapshotId
                    CloudPcId   = $Snapshot.CloudPcId
                } -PreviewScript {
                    param($TargetObject, $Context)

                    [pscustomobject]@{
                        SnapshotId = $Context.SnapshotId
                        CloudPcId   = $Context.CloudPcId
                        Status     = 'WhatIf'
                        Endpoint   = "/deviceManagement/virtualEndpoint/snapshots/$($Context.SnapshotId)"
                    }
                } -SubmitScript {
                    param($TargetObject, $Context)

                    Connect-CloudPC -AdditionalScopes 'CloudPC.ReadWrite.All' | Out-Null
                    $escapedSnapshotId = [uri]::EscapeDataString($Context.SnapshotId)
                    $attempts = [System.Collections.Generic.List[string]]::new()
                    $errors = [System.Collections.Generic.List[string]]::new()

                    $uris = @(
                        "https://graph.microsoft.com/beta/deviceManagement/virtualEndpoint/snapshots/$escapedSnapshotId"
                    )

                    if ($Context.CloudPcId) {
                        $escapedCloudPcId = [uri]::EscapeDataString($Context.CloudPcId)
                        $uris += "https://graph.microsoft.com/beta/deviceManagement/virtualEndpoint/cloudPCs/$escapedCloudPcId/snapshots/$escapedSnapshotId"
                    }

                    foreach ($uri in $uris) {
                        $attempts.Add($uri)
                        try {
                            Invoke-MgGraphRequest -Method DELETE -Uri $uri | Out-Null
                            [pscustomobject]@{
                                SnapshotId = $Context.SnapshotId
                                Status     = 'Deleted'
                                RequestedAt = [datetime]::Now
                                Endpoint   = $uri
                            }
                            return
                        }
                        catch {
                            $message = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $_.Exception.Message }
                            $errors.Add("$uri :: $message")
                        }
                    }

                    throw "Snapshot delete failed. Attempted endpoints: $($attempts -join '; '). Errors: $($errors -join '; ')"
                }
            }
            default {
                return
            }
        }
    }

    end { }
}
