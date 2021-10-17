function grep { 
    [CmdletBinding()] 
    Param
    (
        [Parameter(ValueFromPipeline=$true, Mandatory)] 
        $in, 
        [SupportsWildCards()]
        [Parameter(Position = 0, Mandatory)]
        [string] 
        $pattern,
        [string[]] 
        [Parameter(Position = 1, HelpMessage = "Args ment to Select-String", ValueFromRemainingArguments)]
        $Remaining
    ) 
    write-host ($input | select-object -First 0)  
    $input | ForEach-Object { 
        $t = $_ | Out-String 
        if($_ -is [Microsoft.PowerShell.Commands.MemberDefinition]) {
            $t = $t.Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries) 
        }
        $res = $t | select-string -Pattern $pattern -AllMatches 
        if($res.Line.Length -eq 0 ) {continue}
        $formatedRes = $res.Line.TrimEnd().trimStart()

        write-host $formatedRes
    }

}
