
function mergeArrayString {
    param(
    [Parameter(Position=0)][System.Collections.ArrayList]$array, 
    [parameter(Position=1)][int]$start, 
    [parameter(Position=2)][int]$count
    )
    $i = 0
    $newArray = [System.Collections.ArrayList]::new()
    #iterate all strings
    while ($i -lt $array.count) {
        $newEntry = $null
        if ($i -eq $start) {
            $mergedString = ""
            foreach($index in $start..$count){
                $mergedString += " $($array[$index])"
            }
            $newEntry = $mergedString
        }

        $isWithinMerge = ($i -gt $start) -and ($i -lt $count+$start)
        if($isWithinMerge){
            continue;
        } else {
            $newEntry = $array[$i]
        }


        if($null -ne $newEntry) { $newArray.Add($newEntry) }
        $i += 1
    }
    $newArray
}


function makeColumnNamesUnique() {
    param([string]$CSVHeader)
    $columnNames = $CSVHeader.split(',')
    $repetitionCount = @{}
    $newColumns = [System.Collections.ArrayList]::new($columnNames.Length)
    foreach ($name in $columnNames) {
        $c = 0
        foreach ($col in $columnNames) {
            if ($name -eq $col) {
                $c += 1 
            } 
        }
        $isRepeated = $c -gt 1
        if ($isRepeated) {
            $repetitionCount[$name] = [int]($repetitionCount[$name]) + 1
            $thisRep = $repetitionCount[$name]

            $newColumns.add("$name$thisRep") | Out-Null
        }
        else {
            $newColumns.add($name)  | Out-Null
        }
    }

    write-host $newColumns
    $newColumns -join ','
}

function Convert-ExcelToCsvFile {
    [CmdletBinding()]
    param([string]$Path, [string]$DestinationFolder)
    $Path = Resolve-Path $Path
    $DestinationFolder = $DestinationFolder ? (Resolve-Path $DestinationFolder) : (New-TemporaryFile)

    $Excel = New-Object -ComObject Excel.Application 
    $Excel.DisplayAlerts = $false # remove prompts to substitute file
    $book = $Excel.Workbooks.Open($Path)
    $i = 0
    write-host "Reading sheets:" -NoNewLine
    foreach ($sheet in $book.Worksheets) {
        $savePath = Join-Path $DestinationFolder  "$(split-path $Path -LeafBase)$i.csv"
        # ${VARIABLE WITH A WEIRD NAME AND SPACES} 
        $file = [PSCustomObject]::new($savePath)
        $file | Add-Member -NotePropertyName 'SheetName' -NotePropertyValue $sheet.name
        $sheet.saveAs($savePath, 6) # 6 to save as csv
        $file; $i += 1
    }
    $Excel.Quit() | Out-Null 
}

function  Convert-PDFToCsvFile {
    [CmdletBinding()]
    param([parameter(Position = 0, Mandatory = $true)][string]$Path, [parameter(Position = 1, Mandatory = $true)][string]$DestinationFolder, [switch]$Internals) 
    $Path = Resolve-Path $Path
    $DestinationFolder = $DestinationFolder ? (Resolve-Path $DestinationFolder) : (New-TemporaryFile)
    
    $fname = Split-Path $Path -LeafBase
    $outfile = "$DestinationFolder/$fname"
    # path \ replaced with / !
    py -c "import tabula; tabula.convert_into(r'$($Path.replace('\','/'))',r'$($outfile.replace('\','/'))', output_format = 'csv', pages='all')"    # r strings to not escape chars with \ (hence having an 'can't decode error)
    $outfile
}

function Convert-FileToCsv {
    [CmdletBinding()]
    param(
        [string]$Path, 
        [int]$First, [switch]$Supress,
        [int]$TrimFirst, [int]$MergeEnd, $NameRow, # name row = (rowNr,name),(rowNr,name)
        $ImportCsvArgs,
        [switch]$NoCache, [char]$delimiter, [System.Collections.ArrayList]$HorizonalMerge
    )
    $delimiter = $delimiter ?? ','
    $src = Resolve-Path $Path 
    $fileName = Split-Path $Path -LeafBase
    $tempPath = [System.io.Path]::GetTempPath()
    $cache = Join-Path $tempPath "$fileName.cachu"

    $hasCache = ((Test-Path $cache) -and ( (Get-Item $cache).lastWriteTime -gt (Get-Item $src).lastWriteTime))
    if ( (-not $hasCache) -or $NoCache) {
        $extension = Split-Path $src -Extension 
        switch ($extension) {
            '.pdf' { 
                write-host "Processing file as a pdf..."
                $csvFiles = Convert-PDFToCsvFile -Path $src -DestinationFolder $tempPath
                break
            }
            Default {
                Write-Warning "Filetype not matched, processing file as an excel..."
                $csvFiles = Convert-ExcelToCsvFile -Path $src -DestinationFolder $tempPath
            }
        }
        $csvFiles | Export-Clixml -Path $cache  

    }
    else {
        $csvFiles = Import-CliXml -Path $cache
    }

    # each of this files corresponds to a sheet of the original excel/pdf
    foreach ($file in $csvFiles) {
        $content = Get-Content $file
        $finalContent = $content
        $finalFile = (New-TemporaryFile).FullName

        if ($trimFirst) {
            #antes estava a meter aqui que $finalFile era um tempory object
            #acontece que, como esta operação estava a ser feita eninhadamente
            #depois pensava que estava a usar um file e estava a usar um outro, 
            #alterado por um if obscuro no meio do codigo! ( nem precisa ser obscuro, se estou a trabalhar num scope mais a cima o meu cerebro ignora scopes não relevantes)
            #o melhor é sempre fazer alterações de uma variavel no mesmo scope -> usar funções para isto
            #em que ela é criada!! 
            $finalContent = ($finalContent | Select-Object -skip $trimFirst)
        }
        if ($First) {
            # show first lines
            $finalContent | Select-Object -First $First | write-host 
            write-host "--            Before                      ---"
        }
        set-content $finalFile -Value $finalContent 

        # merges rows [starting from the index MergeStart to MergeEnd] and trims all rows before the merge 
        if ($MergeEnd) {
            $MergeStart ??= 0

            $mergedRow = [System.Collections.ArrayList]$finalContent[$MergeStart].split(',')
            foreach ($row in $finalContent[($MergeStart + 1)..$MergeEnd]) {
                $i = 0
                foreach ($value in $row.split(',')) {
                    if ($mergedRow.count -lt ($i + 1)) {
                        $mergedRow.add(" $value")
                    }
                    else {
                        $mergedRow[$i] += " $value"
                    }
                    $i += 1
                }
            }
            $content[$MergeEnd] = $mergedRow.trim() -join ',' #trim is important to access properties conveniently
            $finalContent = $content[$MergeEnd..$content.Length] 
        }

        $finalContent[0] = makeColumnNamesUnique($finalContent[0]) 

        if ($HorizonalMerge) {
            #vector of merge vectors  [ [1,3], [4,5]  ] -> merge 123 together and 45 
            foreach ($merge in $HorizonalMerge) {
                $i = 1 #start at 1 to skip the header
                while ($i -lt $finalContent.Length) {
                    $row = $finalContent[$i]
                    $row = mergeArrayString($row.split($delimiter), $merge[0], $merge[1])
                    $finalContent[$i] = $row -join $delimiter
                    $i += 1
                }
            }
        }
    }

    if ($First) {
        # show first lines
        $finalContent | Select-Object -First $First | write-host 
    }
    set-content $finalFile -Value $finalContent 
    #set-content -Path $finalCSVFile -Value $finalCSVValue 

    $csvObj = Import-CSV $finalFile @ImportCsvArgs -WarningAction SilentlyContinue #https://stackoverflow.com/questions/363884/what-does-the-symbol-do-in-powershell



    # each row must be outputed one a the time for the command to work with the "pipeline arquitecture"
    $csvObj | ForEach-Object { 
        $row = $_
        $row | Add-Member -NotePropertyName 'SheetName' -NotePropertyValue $file.SheetName # add-member does not return the object
        if (-not $supress -and (-not $First)) {
            $row
        }
    }
}


#Convert-ExcelToCsvFile -Path '~/Downloads/Pauta - 2021 (8).xlsx' -DestinationFolder '.' 
#Convert-FileToCsv '~/Downloads/Pauta - 2021 (8).xlsx' -OutVariable som -First 5 -TrimFirst 2 -Supress
#Convert-PDFToCsvFile -Path 'C:\Users\Tester\Downloads\notas\arquitetura de computadores\pauta-AC-2019-20-v61.pdf' -DestinationFolder '.' 
#Find-ISTPerson -ID -Name  -ShowPhoto --> returns json 
