
function Import-Excel{

}



function Convert-ExcelToCsv{
    [CmdletBinding()]
    param([string]$ExcelFilePath)
    $src = Resolve-Path $ExcelFilePath 
    $fileName = Split-Path $ExcelFilePath -LeafBase
    $tempPath = [System.io.Path]::GetTempPath()
    $csvFiles = [System.Collections.ArrayList]::new()
    $csvObjects = [System.Collections.ArrayList]::new()

    $Excel = New-Object -ComObject Excel.Application 
    $Excel.DisplayAlerts = $false # remove prompts to substitute file
    $book = $Excel.Workbooks.Open($src)


    $i = 0
    write-host "Processed sheets:" -NoNewLine
    foreach ($sheet in $book.Worksheets) {
        $savePath = Join-Path $tempPath  "$fileName.csv"
        write-host " $0" -NoNewLine
        $csvFiles.add($savePath)
        $sheet.saveAs($savePath, 6)
        $sheet.saveAs

        write-host $savePath
        $i +=1
    }

    foreach ($file in $csvFiles) {
        $csvObjects.add((Import-CSV $file))
    }
    $Excel.Quit()

}

Convert-ExcelToCsv '~/Downloads/Pauta - 2021 (8).xlsx'