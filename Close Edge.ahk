; CheckEdge() {
;     if ProcessExist("msedge.exe") { ; Check if Edge process is running
;         if !WinExist("ahk_exe msedge.exe") { ; Check if Edge is not running in the foreground
;             ProcessClose("msedge.exe") ; End the Edge process
;         }
;     }
; }

; SetTimer(CheckEdge, 2000) ; Check every 2 seconds (2000 milliseconds)

loop {
    Sleep(1000)
    if (!ProcessExist("msedge.exe")) {
        continue
    }

    Sleep(1000)
    if (ProcessExist("msedge.exe") && !WinExist("ahk_exe msedge.exe")) {
        ProcessClose("msedge.exe")
    }
}