Set-StrictMode -Version "Latest"

function global:reload() {
    . $PSCommandPath
}

# Load modules.
@(
    "posh-git",
    "PSReadLine"
) | ForEach-Object -Process {
    if (Get-Module -Name $_) {
        Import-Module -Name $_
    } else {
        Write-Warning -Message "$_ module is not installed.  Skipped."
    }
}

# Configure modules.
Set-PSReadlineOption -EditMode Emacs

Out-Host -InputObject "Loaded $PSCommandPath."
