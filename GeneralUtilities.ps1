


function Convert-ExcelToCsvFile {
    [CmdletBinding()]
    param([string]$Path, [string]$DestinationFolder)
    $Path = Resolve-Path $Path
    $DestinationFolder = $DestinationFolder ? (Resolve-Path $DestinationFolder) : (New-TemporaryFile)

    $csvFiles = [System.Collections.ArrayList]::new()
    $Excel = New-Object -ComObject Excel.Application 
    $Excel.DisplayAlerts = $false # remove prompts to substitute file
    $book = $Excel.Workbooks.Open($Path)
    $i = 0
    write-host "Reading sheets:" -NoNewLine
    foreach ($sheet in $book.Worksheets) {
        $savePath = Join-Path $DestinationFolder  "${split-path $path -LeafBase}$i.csv"
        write-host " $0" -NoNewLine
        $csvFiles.add($savePath)
        $sheet.saveAs($savePath, 6) # 6 to save as csv
        $i += 1
    }
    $Excel.Quit() | Out-Null 
    $csvFiles
}

function  Convert-PDFToCsvFile {
    [CmdletBinding()]
    param([parameter(Position = 0)][string]$Path, [parameter(Position = 1)][string]$DestinationFolder, [switch]$Internals) 
    $Path = Resolve-Path $Path
    $DestinationFolder = $DestinationFolder ? (Resolve-Path $DestinationFolder) : (New-TemporaryFile)
    
    $fname = Split-Path $Path -LeafBase
    $outfile = "$DestinationFolder/$fname"
    py -c "import tabula; tabula.convert_into(r'$($Path.replace('\','/'))',r'$($outfile.replace('\','/'))', output_format = 'csv', pages='all')"   
    $outfile
}

function Convert-FileToCsv {
    [CmdletBinding()]
    param([string]$Path, [int]$First, [int]$TrimFirst, [switch]$Supress, [int]$MergeEnd, [switch]$NoCache)
    $src = Resolve-Path $Path 
    $fileName = Split-Path $Path -LeafBase
    $tempPath = [System.io.Path]::GetTempPath()
    $cache = Join-Path $tempPath "$fileName.cachy"
    $csvObjects = [System.Collections.ArrayList]::new()

    $hasCachedConversion = ((Test-Path $cache) -and ( (Get-Item $cache).lastWriteTime -gt (Get-Item $src).lastWriteTime))
    if ( (-not $hasCachedConversion) -or $NoCache) {
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

        # merges rows [starting from the index MergeStart to MergeEnd] and trims all rows before the merge 
        if ($MergeEnd) {
            $MergeStart ??= 0

            write-host "$($finalContent[0])"
            write-host "$($finalContent[1])"
            write-host "$($finalContent[2])"
            write-host "$($finalContent[3])"
            $mergedRow = [System.Collections.ArrayList]$finalContent[$MergeStart].split(',')
            write-host "MergedRow before: $($mergedRow -join ',')"
            foreach ($row in $finalContent[($MergeStart + 1)..$MergeEnd]) {
                $i = 0
                write-host $row
                foreach ($value in $row.split(',')) {
                    if ($mergedRow.count -lt ($i+1)) {
                        $mergedRow.add(" $value")
                    } else {
                        $mergedRow[$i] += " $value"
                    }
                    $i += 1
                }
            }
            $content[$MergeEnd] = $mergedRow.trim() -join ',' #trim is important to access properties conveniently
            $finalContent = $content[$MergeEnd..$content.Length] 
            write-host "MergedRow after: $($mergedRow -join ',')"
        }
        if ($First) {
            $finalContent | Select-Object -First $First | write-host 
        }



        set-content $finalFile -Value $finalContent 
        #set-content -Path $finalCSVFile -Value $finalCSVValue 
        $csvObj = Import-CSV $finalFile
        #$csvObj | Add-Member -NotePropertyName 'FromOriginalFile' -NotePropertyValue $file 
        #$csvObj | Add-Member -NotePropertyName 'FromFile' -NotePropertyValue $finalCSVFile
        $csvObjects.add($csvObj) | Out-Null
    }
    if (-not $supress -and (-not $First)) {
        $csvObjects
    }
}

#Convert-ExcelToCsvFile -Path '~/Downloads/Pauta - 2021 (8).xlsx' -DestinationFolder '.' 
#Convert-FileToCsv '~/Downloads/Pauta - 2021 (8).xlsx' -OutVariable som -First 5 -TrimFirst 2 -Supress
#Convert-PDFToCsvFile -Path 'C:\Users\Tester\Downloads\notas\arquitetura de computadores\pauta-AC-2019-20-v61.pdf' -DestinationFolder '.' 
#Find-ISTPerson -ID -Name  -ShowPhoto --> returns json 
