Set-PSReadLineOption -EditMode Emacs

set-alias wc measure
set-alias vim nvim
function touch {
     param($path)
     $path | ForEach-Object { set-content -Path  $_ -Value ''}
}

$_emptyLine = "\r\n\r\n"
#Import-Module -Name Terminal-Icons
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


Import-Module "$($profile | split-path -Parent)\ConvertTo-NamedPath.ps1" # Import-Module > . (source operator) --> variables inside the script are only accessable by the functions inside it!

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

