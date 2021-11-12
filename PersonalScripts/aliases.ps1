set-alias wc measure
set-alias vim nvim
function touch {
     param($path)
     $path | ForEach-Object { set-content -Path  $_ -Value ''}
}