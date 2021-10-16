$__namedPaths = @{
     $HOME = '[~]'
}
function decorateAlias {
     param($alias)
     "[$alias]"
}
function ConvertTo-NamedPath {
     param ( [string] $path)
     $pathList = [System.Collections.ArrayList]@()
     $p = [System.Collections.ArrayList]$path.split('\', [System.StringSplitOptions]::RemoveEmptyEntries)

     $drive = $p[0]
     $p.RemoveAt(0) | Out-Null
     foreach ($i in ($p.count - 1)..0) {
          if ($i -lt 0) { break } # edge case when array is empty
          $item = $p[$i]
          $itemPath = ($drive, $p[0..$i] | Join-String -Separator \)   

          $alias = $__namedPaths[$itemPath]
          if ($null -eq $alias) {
               $shouldAlias = (Test-Path ($itemPath + "\" + ".git"))
               $alias = $shouldAlias ? (Add-NamedPath $itemPath $item -PassThru) : $alias
          } 
          $pathList.Insert(0, $alias ?? $item)
          if ($alias) { break }
     }
     $pathList
}


# add passthru
function Add-NamedPath {
     param (
          $path, $name, [switch]$PassThru
     )
     if ('/' -in $path.Split()) { Write-Error "Paths must be separated by '\'!, instead got $path" }
     $alias = decorateAlias $name
     $__namedPaths[$path] = $alias 
     if ($PassThru) { $alias }
}