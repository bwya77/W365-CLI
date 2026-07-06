function Get-W365CliConnection {
    [CmdletBinding()]
    param()

    begin { }

    process {
        if (-not (Get-Command -Name Get-MgContext -ErrorAction SilentlyContinue)) {
            return $null
        }

        Get-MgContext
    }

    end { }
}
