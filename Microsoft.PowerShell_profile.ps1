Set-PSReadLineOption -EditMode Emacs
write-host Welcome back, what are your commands?

$quickblock =  {
     param($key)
     
     [Microsoft.PowerShell.PSConsoleReadLine]::Insert($key+' {$_. }') # pelicas -> verbatim " -> faz expansao de vars
     [Microsoft.PowerShell.PSConsoleReadLine]::BackwardChar($null, 2)    
}

Set-PSReadLineKeyHandler -Chord '?' -ScriptBlock { Invoke-Command $quickblock -ArgumentList ?}
Set-PSReadLineKeyHandler -Chord '%' -ScriptBlock { Invoke-Command $quickblock -ArgumentList %}

# se só tiver espaços antes -> adicionar pipe 
#se tiver letras antes adicionar apenas o char

#Remove-Variable -Name quickblock
