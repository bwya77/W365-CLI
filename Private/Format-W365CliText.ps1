function Format-W365CliText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Text,

        [Parameter(Mandatory)]
        [ValidateRange(1, 200)]
        [int]$Width
    )

    begin { }

    process {
        $value = if ($null -eq $Text -or "$Text" -eq '') { '-' } else { "$Text" }
        if ($value.Length -gt $Width) {
            return ($value.Substring(0, [math]::Max(1, $Width - 3)) + '...')
        }

        $value.PadRight($Width)
    }

    end { }
}
