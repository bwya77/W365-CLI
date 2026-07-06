function Get-W365CloudAppData {
    [CmdletBinding()]
    param(
        [ValidateSet('All','Ready','Failed')]
        [string]$Status = 'All'
    )

    begin {
        Import-W365CliWindowsCloudPC
        Connect-CloudPC | Out-Null
    }

    process {
        $baseUri = 'https://graph.microsoft.com/beta/deviceManagement/virtualEndpoint/cloudApps'
        $query = [System.Collections.Generic.List[string]]::new()
        $query.Add('$top=100')
        $query.Add('$count=true')

        switch ($Status) {
            'Ready' {
                $query.Add('$orderBy=addedDateTime desc')
                $query.Add('$filter=appStatus eq ''ready''')
                $query.Add('$select=*')
            }
            'Failed' {
                $query.Add('$orderBy=addedDateTime desc')
                $query.Add('$filter=appStatus eq ''failed''')
                $query.Add('$select=*')
            }
            default {
                $query.Add('$orderBy=lastPublishedDateTime desc')
                $query.Add('$select=*')
            }
        }

        $uri = "$baseUri`?$($query -join '&')"
        do {
            $response = Invoke-MgGraphRequest -Method GET -Uri $uri -Headers @{ ConsistencyLevel = 'eventual' }
            foreach ($app in @($response.value)) {
                $displayName = if ($app.displayName) {
                    $app.displayName
                }
                elseif ($app.appName) {
                    $app.appName
                }
                elseif ($app.discoveredAppName) {
                    $app.discoveredAppName
                }
                else {
                    $app.id
                }

                [pscustomobject]@{
                    PSTypeName            = 'W365CLI.CloudApp'
                    Id                    = $app.id
                    DisplayName           = $displayName
                    AppStatus             = $app.appStatus
                    AppType               = $app.appType
                    Description           = $app.description
                    Publisher             = $app.publisher
                    Version               = $app.version
                    DiscoveredAppName     = $app.discoveredAppName
                    AddedDateTime         = if ($app.addedDateTime) { ([datetime]$app.addedDateTime).ToLocalTime() } else { $null }
                    LastPublishedDateTime = if ($app.lastPublishedDateTime) { ([datetime]$app.lastPublishedDateTime).ToLocalTime() } else { $null }
                    Raw                   = $app
                }
            }

            $uri = $response.'@odata.nextLink'
        } while ($uri)
    }

    end { }
}
