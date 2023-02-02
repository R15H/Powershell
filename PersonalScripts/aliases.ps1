set-alias wc measure
set-alias vim nvim
set-alias l ls
function touch {
     param($path)
     $path | ForEach-Object { set-content -Path  $_ -Value ''}
}