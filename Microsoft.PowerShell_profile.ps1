﻿# Set-StrictMode -Version "Latest" # posh-git cannot show the first prompt correctly in the strict mode

Import-Module -Name "posh-git"
Import-Module -Name "PSReadLine"
Set-PSReadlineOption -EditMode Emacs

function global:Get-GitDefaultPromptPrefixText() {
    [string] $prompt = ""
    [Microsoft.PowerShell.Commands.HistoryInfo] $lastCommand = Get-History -Count 1
    if ($lastCommand) {
        $prompt += "`n"
    }

    # Prompt the command sequential ID.
    $prompt += "#$((Get-History -Count 1).Id + 1) "

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

function global:Get-GitDefaultPromptSuffixForegroundColor() {
    if ($?) {
        return [ConsoleColor]::Green
    }
    else {
        return [ConsoleColor]::Red
    }
}

function global:Get-GitDefaultPromptBeforeSuffixText() {
    if (Get-Variable -Name "GitPromptValues" -Scope "Global") {
        if ($global:GitPromptValues.DollarQuestion) {
            return Write-Prompt -ForegroundColor [ConsoleColor]::Green -Object "`n"
        }

        if ($global:GitPromptValues.LastExitCode) {
            return Write-Prompt -ForegroundColor [ConsoleColor]::Red -Object "[${global:GitPromptValues.LastExitCode}]`n"
        }
        else {
            return Write-Prompt -ForegroundColor [ConsoleColor]::Red -Object "`n"
        }
    }
    else {
        if ($?) {
            return Write-Prompt -ForegroundColor [ConsoleColor]::Green -Object "`n"
        }
        else {
            return Write-Prompt -ForegroundColor [ConsoleColor]::Red -Object "`n"
        }
    }
}

function global:Get-GitDefaultPromptPathText {
  $status = Get-GitStatus
  if ($status `
      -and ($status | Get-Member -Name "GitDir") `
      -and ($status | Get-Member -Name "RepoName")) {
    return $status.RepoName + ":" + [IO.Path]::GetRelativePath($status.GitDir + "\..\", $PWD)
  }
  else {
    return Get-PromptPath
  }
}

function Redo-Profile()
{
    . $PSCommandPath
}

[string] $localProfilePath = [IO.Path]::ChangeExtension($PSCommandPath, "$env:COMPUTERNAME.ps1")
if (Test-Path -LiteralPath $localProfilePath)
{
    . $localProfilePath
}

Set-Alias -Name "reload" -Value "Redo-Profile"

$GitPromptSettings.DefaultPromptBeforeSuffix.Text = '$(Get-GitDefaultPromptBeforeSuffixText)'
$GitPromptSettings.DefaultPromptPath.ForegroundColor = [ConsoleColor]::DarkYellow
$GitPromptSettings.DefaultPromptPath.Text = '$(Get-GitDefaultPromptPathText)'
$GitPromptSettings.DefaultPromptPrefix.ForegroundColor = [ConsoleColor]::DarkGray
$GitPromptSettings.DefaultPromptPrefix.Text = '$(Get-GitDefaultPromptPrefixText)'
$GitPromptSettings.DefaultPromptSuffix.ForegroundColor = '$(Get-GitDefaultPromptSuffixForegroundColor)'

Write-Debug -Message "Loaded $PSCommandPath."

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path -LiteralPath $ChocolateyProfile)
{
    Import-Module "$ChocolateyProfile"
}