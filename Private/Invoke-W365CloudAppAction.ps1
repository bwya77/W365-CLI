function Invoke-W365CloudAppAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CloudApp,

        [string]$Action
    )

    begin {
        Import-W365CliWindowsCloudPC
    }

    process {
        $endpointAction = switch ($Action) {
            'Publish' { 'publish' }
            'Unpublish' { 'unpublish' }
            default { $null }
        }

        if (-not $endpointAction) {
            return
        }

        Invoke-W365CloudPCConfirmedAction -CloudPC ([pscustomobject]@{
            Name = $CloudApp.DisplayName
        }) -ActionName $Action -TargetType 'cloud app' -Context @{
            CloudAppId = $CloudApp.Id
            Action     = $endpointAction
        } -PreviewScript {
            param($Target, $Context)

            [pscustomobject]@{
                CloudAppId = $Context.CloudAppId
                Action     = $Context.Action
                Status     = 'WhatIf'
                Endpoint   = "/deviceManagement/virtualEndpoint/cloudApps/$($Context.Action)"
            }
        } -SubmitScript {
            param($Target, $Context)

            Connect-CloudPC -AdditionalScopes 'CloudPC.ReadWrite.All' | Out-Null
            $uri = "https://graph.microsoft.com/beta/deviceManagement/virtualEndpoint/cloudApps/$($Context.Action)"
            $body = @{ cloudAppIds = @($Context.CloudAppId) } | ConvertTo-Json -Depth 5 -Compress
            Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType 'application/json' | Out-Null
            [pscustomobject]@{
                CloudAppId  = $Context.CloudAppId
                Action      = $Context.Action
                Status      = 'Submitted'
                RequestedAt = [datetime]::Now
            }
        }

        $script:W365CliCloseDetailRequested = $true
    }

    end { }
}
