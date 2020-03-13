Set-StrictMode -Version "Latest"

Import-Module -Name "posh-git"
Import-Module -Name "PSReadLine"
Set-PSReadlineOption -EditMode Emacs

Out-Host -InputObject "Loaded $PSCommandPath."
