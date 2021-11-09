function Set-WinWindowStyle {
param(
    [Parameter()]
    [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE', 
                 'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED', 
                 'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
    $Style = 'SHOW',
    [Parameter()]
    $MainWindowHandle = (Get-Process -Id $pid).MainWindowHandle
)
    $WindowStates = @{
        FORCEMINIMIZE   = 11; HIDE            = 0
        MAXIMIZE        = 3;  MINIMIZE        = 6
        RESTORE         = 9;  SHOW            = 5
        SHOWDEFAULT     = 10; SHOWMAXIMIZED   = 3
        SHOWMINIMIZED   = 2;  SHOWMINNOACTIVE = 7
SHOWNA          = 8;  SHOWNOACTIVATE  = 4
        SHOWNORMAL      = 1
    }
    Write-Verbose ("Set Window Style {1} on handle {0}" -f $MainWindowHandle, $($WindowStates[$style]))

    $Win32ShowWindowAsync = Add-Type –memberDefinition @” 
    [DllImport("user32.dll")] 
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru

    $Win32ShowWindowAsync::ShowWindowAsync($MainWindowHandle, $WindowStates[$Style]) | Out-Null
}


function ReadlineWindowHandler{
    param(
        $style = 'MAXIMIZE'
    )
    # [PSConsoleReadLine]::ReadLine()
    # alt 0 -> Code Editor (Search for Intelij/VS Code)
    # alt 1 -> 
    # alt 2 ->
    # alt 8 -> Notes (Evernote/OneNote/Notepad/StickyNotes)

    Get-Process | Where-Object {$_.ProcessName -like $name -and $_.MainWindowHandle.ToInt32()} |
     ForEach-Object {Set-WindowStyle $_.MainWindowHandle -Style $style}
}

#ps | ? {$_.MainWindowTitle -like "*Evernote*"} | % {Set-WindowStyle $_.MainWindowHandle -Style MAXIMIZE }