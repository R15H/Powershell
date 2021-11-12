$ProfileFolder = Split-Path $PROFILE -Parent
. "$ProfileFolder/PersonalScripts/aliases.ps1"
. "$ProfileFolder/FileUtilities.ps1"

Import-Module "$ProfileFolder\ConvertTo-NamedPath.ps1" 


Set-PSReadLineOption -EditMode Emacs


$_emptyLine = "\r\n\r\n"

write-host Welcome back, what are your commands?

$__quickblock = {
     param($key)
     [Microsoft.PowerShell.PSConsoleReadLine]::Insert($key + ' {$_. }') # pelicas -> verbatim " -> faz expansao de vars
     [Microsoft.PowerShell.PSConsoleReadLine]::BackwardChar($null, 2)    
}

Set-PSReadLineKeyHandler -Chord '?' -ScriptBlock { Invoke-Command $__quickblock -ArgumentList ? }
Set-PSReadLineKeyHandler -Chord '%' -ScriptBlock { Invoke-Command $__quickblock -ArgumentList % }

# se só tiver espaços antes -> adicionar pipe 
#se tiver letras antes adicionar apenas o char



Add-NamedPath "$HOME\Downloads" '⬇️'
Add-NamedPath "$HOME\Documents" '📜'
function prompt {
     $path = (Get-Location)
     [string[]]$parsedPath = ConvertTo-NamedPath $path.Path 
     $hasAlias = ${parsedPath}?[0] -match '\[.*'
     
     if ($hasAlias) { $parsedPath[0] = $parsedPath[0] + " " }
     $temp = $parsedPath | Join-String -Separator '\' 
     $resultPath = $hasAlias ? $temp.Replace('] \', '] ') : $temp 
     $path.drive.name + " " + $resultPath + "$ "                                           # use drive.name instead of root because Providers always have name but may not have a root
}

