$__namedPaths = @{
     $HOME = '~'
     #"$HOME/Downloads" = '⬇️'
}
function ConvertTo-NamedPath {
     param
     (
          [string] $path
     )
     [string] $namedPath = ''

     $p = $path.split('\', [System.StringSplitOptions]::RemoveEmptyEntries)
     foreach ($i in ($p.length - 1)..0) {
          $item = $p[$i]
          $itemPath = ($p[0..$i] | Join-String -Separator \)   

          $alias = $__namedPaths[$itemPath]
          if ($null -eq $alias) {
               # search if this can be aliased
               $isAliasable = (Test-Path ($itemPath  + "\" + ".git"))

               <# 6 lines vs 2 with trenary operator
               if($isAliasable){
                    $__namedPaths[$i] = $itemPath 
                    $alias =  $item
               }else {
                    $__namedPaths[$i] = $false
               }
               #>

               $__namedPaths[$i] = $isAliasable ? $itemPath : $False
               $alias = $isAliasable ?  $item : $null 

          } 
          <#Coalescing operator: 3 lines vs 1 and provides an unique line of logic for messing with __NamedPaths#>
       
          $namedPath = $namedPath.Insert(0, $alias ?? $item)
          if($alias || $isAliasable){break}
     }
     $namedPath  # return == Write-Output , but exits the function!
}