Set-PSReadLineOption -EditMode Emacs
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

#Add-NamedPath "$HOME\Downloads" '⬇️'
#Add-NamedPath "$HOME\Documents" '📜'
function prompt {
     $path = (Get-Location)
     [string[]]$parsedPath = ConvertTo-NamedPath $path.Path 
     $hasAlias = ${parsedPath}?[0] -match '\[.*'
     
     if ($hasAlias) {
          $parsedPath[0] = " " + $parsedPath[0] + " "
          $resultPath = ($parsedPath | Join-String -Separator '\').Substring(1) 
     } else { 
          $resultPath = $parsedPath | Join-String -Separator '\' 
     }
     $temp = Join-String -Separator '\' 
     $resultPath = $hasAlias ? $temp.Substring(1) : $temp

     $path.drive.root + $resultPath + "$ "
}

#Remove-Variable -Name quickblock
