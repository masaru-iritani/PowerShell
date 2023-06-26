<#
.SYNOPSIS
    Sets the default terminal app on Windows 11.

.DESCRIPTION
    This function updates the registry key
    to change the default terminal app for the current user.
    https://support.microsoft.com/en-us/windows/command-prompt-and-windows-powershell-for-windows-11-6453ce98-da91-476f-8651-5c14d5777c20

.NOTES
    This function supports Windows 11 22H2 or later only.

.EXAMPLE
    # Sets Windows Terminal as the default terminal app.
    Set-WindowsDefaultTerminalApp WindowsTerminal
#>
function Set-WindowsDefaultTerminalApp
{
    param
    (
        # Specify the default terminal application.
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('Auto', 'WindowsConsoleHost', 'WindowsTerminal')]
        [string]
        $App
    )

    [string] $path = New-Item -Path HKCU:\Console -Name '%%Startup' -Force `
    | Select-Object -ExpandProperty 'PSPath'

    @($App) `
    | ForEach-Object -Process {
        switch ($_)
        {
            'WindowsConsoleHost'
            {
                @{
                    DelegationConsole = '{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}'
                    DelegationTerminal = '{B23D10C0-E52E-411E-9D5B-C09FDF709C7D}'
                }
            }

            'WindowsTerminal'
            {
                @{
                    DelegationConsole = '{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}'
                    DelegationTerminal = '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}'
                }
            }

            default
            {
                @{
                    DelegationConsole = [Guid]::Empty.ToString()
                    DelegationTerminal = [Guid]::Empty.ToString()
                }
            }
        }
    } `
    | ForEach-Object -MemberName 'GetEnumerator'
    | ForEach-Object -Process `
    {
        New-ItemProperty `
            -Path $path `
            -Name $_.Name `
            -PropertyType 'String' `
            -Value $_.Value `
            -Force
    } `
    | Out-Null
}