
function Import-Excel {

}


function -Csv {
    [CmdletBinding()]
    param([string]$Path, [int]$ShowFirst, [int]$TrimFirst, [switch]$Supress)
    $src = Resolve-Path $Path 
    $fileName = Split-Path $Path -LeafBase
    $tempPath = [System.io.Path]::GetTempPath()
    $cache = Join-Path $tempPath "$fileName.cachy"
    $csvFiles = [System.Collections.ArrayList]::new()
    $csvObjects = [System.Collections.ArrayList]::new()

    $hasCachedConversion = ((Test-Path $cache) -and ( (Get-Item $cache).lastWriteTime -gt (Get-Item $src).lastWriteTime))

    if (-not $hasCachedConversion) {
        $csvFiles = Convert-ExcelToCsv -Path $src -DestinationFolder $tempPath
    } else {
        $csvFiles = Import-CliXml -Path $cache
    }


    foreach ($file in $csvFiles) {
        $finalCSVFile = $file
        $content = Get-Content $finalCSVFile
        if($ShowFirst){
            $content | select -First $ShowFirst | write-host 
        }
        if($trimFirst){
            $finalCSVFile = New-TemporaryFile
            set-content $finalCSVFile -Value ($content | select -skip $trimFirst)
        }
        $csvObj = Import-CSV $finalCSVFile
        #$csvObj | Add-Member -NotePropertyName 'FromOriginalFile' -NotePropertyValue $file 
        #$csvObj | Add-Member -NotePropertyName 'FromFile' -NotePropertyValue $finalCSVFile
        $csvObjects.add($csvObj)
    }
    if(-not $supress -and (-not $ShowFirst)){
        $csvObjects
    }
}
function Convert-ExcelToCsv {
    if (-not $hasCachedConversion) {
        $Excel = New-Object -ComObject Excel.Application 
        $Excel.DisplayAlerts = $false # remove prompts to substitute file
        $book = $Excel.Workbooks.Open($src)
        $i = 0
        write-host "Reading sheets:" -NoNewLine
        foreach ($sheet in $book.Worksheets) {
            $savePath = Join-Path $tempPath  "$fileName$i.csv"
            write-host " $0" -NoNewLine
            $csvFiles.add($savePath)
            $sheet.saveAs($savePath, 6) # 6 to save as csv
            $i += 1
        }
        Export-CliXml -Path $cache -InputObject $csvFiles 
        Start-Job $Excel.Quit()
    }
}

function Convert-ExcelToCsv{
    [CmdletBinding()]
    param([string]$Path,[string]$DestinationFolder, [int]$ShowFirst, [int]$TrimFirst, [switch]$Supress)
    $src = Resolve-Path $Path 
    $fileName = Split-Path $Path -LeafBase
    $tempPath = [System.io.Path]::GetTempPath()
    $cache=  Join-Path $tempPath "$fileName.cachy"
    $csvFiles = [System.Collections.ArrayList]::new()
    $csvObjects = [System.Collections.ArrayList]::new()

    $hasCachedConversion = ((Test-Path $cache) -and ( (Get-Item $cache).lastWriteTime -gt (Get-Item $src).lastWriteTime))
    if(-not $hasCachedConversion){
        $Excel = New-Object -ComObject Excel.Application 
        $Excel.DisplayAlerts = $false # remove prompts to substitute file
        $book = $Excel.Workbooks.Open($src)
        $i = 0
        write-host "Reading sheets:" -NoNewLine
        foreach ($sheet in $book.Worksheets) {
            $savePath = Join-Path $DestinationFolder  "$fileName$i.csv"
            write-host " $0" -NoNewLine
            $csvFiles.add($savePath)
            $sheet.saveAs($savePath, 6) # 6 to save as csv
            $i +=1
        }
        Export-CliXml -Path $cache -InputObject $csvFiles 
        Start-Job $Excel.Quit()
    } else {
        $csvFiles = Import-CliXml -Path $cache
    }

}

 #Convert-ExcelToCsv '~/Downloads/Pauta - 2021 (8).xlsx' -OutVariable som -ShowFirst 5 -TrimFirst 2 -Supress
 #Find-ISTPerson -ID -Name  -ShowPhoto --> returns json 