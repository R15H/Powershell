


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
    param([parameter(Position = 0)][string]$Path, [parameter(Position = 1)][string]$DestinationFolder, [switch]$Internals) 
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
        [int]$TrimFirst, [int]$MergeEnd,$NameRow,  # name row = (rowNr,name),(rowNr,name)
        [switch]$NoCache
    )
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
        if ($First) {
            $finalContent | Select-Object -First $First | write-host 
        }

        set-content $finalFile -Value $finalContent 
        #set-content -Path $finalCSVFile -Value $finalCSVValue 
        $csvObj = Import-CSV $finalFile -WarningAction SilentlyContinue



        # each row must be outputed one a the time for the command to work with the "pipeline arquitecture"
        $csvObj | ForEach-Object { 
            $row = $_
            $row | Add-Member -NotePropertyName 'SheetName' -NotePropertyValue $file.SheetName # add-member does not return the object
            if (-not $supress -and (-not $First)) {
                $row
            }
        }
    }
}

#Convert-ExcelToCsvFile -Path '~/Downloads/Pauta - 2021 (8).xlsx' -DestinationFolder '.' 
#Convert-FileToCsv '~/Downloads/Pauta - 2021 (8).xlsx' -OutVariable som -First 5 -TrimFirst 2 -Supress
#Convert-PDFToCsvFile -Path 'C:\Users\Tester\Downloads\notas\arquitetura de computadores\pauta-AC-2019-20-v61.pdf' -DestinationFolder '.' 
#Find-ISTPerson -ID -Name  -ShowPhoto --> returns json 
