<#
.SYNOPSIS
    Sets convenient global Git aliases.

.DESCRIPTION
    This function sets two-character global Git aliases for the convenience.
    It assumes "git" command is available.

.EXAMPLE
    Set-GitAlias
#>


function Set-GitAlias
{
    [CmdletBinding()]
    param
    (
    )

    git config --global --replace-all alias.ap 'add -p'
    git config --global --replace-all alias.br 'branch'
    git config --global --replace-all alias.co 'checkout'
    git config --global --replace-all alias.df 'diff'
    git config --global --replace-all alias.ds 'diff --staged'
    git config --global --replace-all alias.fa 'fetch --all --prune'
    git config --global --replace-all alias.l 'log --oneline'
    git config --global --replace-all alias.st 'status'
}