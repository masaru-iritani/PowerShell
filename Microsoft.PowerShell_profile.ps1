$parentDirectory = Split-Path -Path $PSCommandPath -Parent
Import-Module -Name (Join-Path -Path $parentDirectory -ChildPath 'MaIritan.psm1')

Get-Module -Name 'posh-git' | Import-Module
Get-Module -Name 'PSReadLine' | Import-Module
if (Get-Command -Name 'Set-PSReadLineOption' -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -EditMode Emacs
    $emacsKeyHandlers = Get-PSReadLineKeyHandler
    Set-PSReadLineOption -EditMode Windows
    # Overwrite Emacs key handlers on top of Windows key handlers.
    $emacsKeyHandlers | Where-Object -FilterScript {
        # For "Ctrl + Backspace", prefer BackwardKillWord in Windows edit mode
        # rather than BackwardDeleteChar in Emacs edit mode.
        # Skip "Ctrl + Alt + ?", otherwise the same key handler is set for "?" and blocks inputting "?".
        # https://github.com/PowerShell/PSReadLine/issues/3508
        ($_.Key -ne 'Ctrl+Backspace') -and ($_.Key -ne 'Ctrl+Alt+?')
    } | ForEach-Object -Process {
        Set-PSReadLineKeyHandler -Chord $_.Key -Function $_.Function
    }

    Set-PSReadLineKeyHandler -Chord 'Ctrl+i' -Function Complete
} else {
    Write-Warning -Message "Skipping PSReadLine configurations because it's unavailable."
}

function global:Get-GitDefaultPromptPrefixText() {
    [string] $prompt = ""

    # Prompt the command sequential ID.
    [Microsoft.PowerShell.Commands.HistoryInfo] $lastCommand = Get-History -Count 1
    if ($lastCommand) {
        $prompt += "`n#$((Get-History -Count 1).Id + 1) "
    }
    else {
        $prompt += "#1 "
    }

    # Prompt the current date time.
    $prompt += Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

    # Prompt the elapsed time of the last command on PowerShell 7+, where HistoryInfo.Duration is available.
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        if ($lastCommand) {
            [TimeSpan] $duration = $lastCommand.Duration
            $prompt += " (+{0}:{1:00})" -f (([int]($duration.TotalMinutes)), ([int]($duration.Seconds)))
        }
    }

    $prompt += "`n"
    return $prompt
}

function global:Get-GitDefaultPromptSuffixText() {
    [string] $prompt = $(">" * ($nestedPromptLevel + 1)) + " "
    [ConsoleColor] $foregroundColor = if ($?) { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
    return Write-Prompt -Object $prompt -ForegroundColor $foregroundColor
}

function global:Get-GitDefaultPromptBeforeSuffixText() {
    # Prompt the last error exit code in red.
    if ((Get-Variable -Name "GitPromptValues" -Scope "Global") `
            -and !$global:GitPromptValues.DollarQuestion `
            -and $global:GitPromptValues.LastExitCode) {
        return Write-Prompt -ForegroundColor Red -Object " !$($global:GitPromptValues.LastExitCode)!`n"
    }

    return "`n"
}

function global:Get-GitDefaultPromptPathText {
    # Prompt the relative path in the current repository.
    $status = Get-GitStatus
    if ($status `
            -and ($status | Get-Member -Name "GitDir") `
            -and ($status | Get-Member -Name "RepoName")) {
        return $status.RepoName + ":" + [IO.Path]::GetRelativePath($status.GitDir + "\..\", $PWD)
    }

    return Get-PromptPath
}

function Redo-Profile() {
    . $PSCommandPath
}

# Load the device specific profile if it exists.
[string] $localProfilePath = [IO.Path]::ChangeExtension($PSCommandPath, "$env:COMPUTERNAME.ps1")
if (Test-Path -LiteralPath $localProfilePath) {
    . $localProfilePath
}

Set-Alias -Name "reload" -Value "Redo-Profile"

[PSModuleInfo] $poshGit = Get-Module -ListAvailable -Name 'posh-git' `
    | Sort-Object -Property 'Version' -Descending `
    | Select-Object -First 1
if ($poshGit) {
    Import-Module -ModuleInfo $poshGit
    if ($poshGit.Version -ge ([System.Version] '1.0.0')) {
        $GitPromptSettings.DefaultPromptBeforeSuffix.Text = '$(Get-GitDefaultPromptBeforeSuffixText)'
        $GitPromptSettings.DefaultPromptPath.ForegroundColor = [ConsoleColor]::DarkYellow
        $GitPromptSettings.DefaultPromptPath.Text = '$(Get-GitDefaultPromptPathText)'
        $GitPromptSettings.DefaultPromptPrefix.ForegroundColor = [ConsoleColor]::DarkGray
        $GitPromptSettings.DefaultPromptPrefix.Text = '$(Get-GitDefaultPromptPrefixText)'
        $GitPromptSettings.DefaultPromptSuffix.Text = '$(Get-GitDefaultPromptSuffixText)'
    } else {
        Write-Warning -Message 'Skipped setting the Git prompt because posh-git is older than 1.0.0-beta4.'
    }
} else {
    Write-Warning -Message 'Skipped loading posh-git because it is not available.'
}

Write-Information -InformationAction Continue -Message "Loaded $PSCommandPath."

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path -LiteralPath $ChocolateyProfile) {
    Import-Module "$ChocolateyProfile"
}
