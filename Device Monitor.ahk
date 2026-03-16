#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Create WMI objects for device monitoring
try {
    wmi := ComObjGet("winmgmts:")
    events := wmi.ExecNotificationQuery("SELECT * FROM Win32_DeviceChangeEvent")
} catch {
    MsgBox("Failed to initialize WMI for device monitoring.")
    ExitApp
}

; Initialize counters
totalConnections := 0
totalDisconnections := 0
lastConnectionTime := "N/A"
lastDisconnectionTime := "N/A"

; Function to set tray icon tooltip
SetIconTip() {
    A_IconTip := "Connection Events: " . totalConnections . "`n    Last: " . lastConnectionTime . "`nDisconnection Events: " . totalDisconnections . "`n    Last: " . lastDisconnectionTime
}

; Event type constants
DEVICE_ARRIVAL := 2
DEVICE_REMOVAL := 3

; Flag to prevent concurrent processing
isProcessing := false

CheckDeviceEvents() {
    global totalConnections, totalDisconnections, isProcessing, lastConnectionTime, lastDisconnectionTime

    if (isProcessing) {
        return  ; Prevent concurrent processing
    }
    else {
        isProcessing := true
    }

    newConnections := 0
    newDisconnections := 0

    loop {
        try {
            ; Check for pending WMI events
            eventType := events.NextEvent(0).EventType  ; only past and just-in-time events, no timeout
            if (eventType = DEVICE_ARRIVAL) {
                lastConnectionTime := FormatTime(A_Now, "yyyy-MMM-dd hh:mm:ss tt")
                newConnections++
            } else if (eventType = DEVICE_REMOVAL) {
                lastDisconnectionTime := FormatTime(A_Now, "yyyy-MMM-dd hh:mm:ss tt")
                newDisconnections++
            }
        }
        catch {
            break  ; No more events, exit loop
        }
    }

    ; Handle different event types - only show one notification per type
    ; Both connected and disconnected
    if (newConnections > 0 && newDisconnections > 0) {
        totalConnections += newConnections
        totalDisconnections += newDisconnections
        TrayTip(newConnections " device(s) connected. Last Time: " lastConnectionTime "`n" newDisconnections " device(s) disconnected. Last Time: " lastDisconnectionTime, "Devices Changed", 1)
    }
    ; Only device connected/inserted
    else if (newConnections > 0) {
        totalConnections += newConnections
        TrayTip(newConnections " device(s) connected.`nLast Time: " lastConnectionTime, "Device Connected", 1)
    }
    ; Only device disconnected/removed
    else if (newDisconnections > 0) {
        totalDisconnections += newDisconnections
        TrayTip(newDisconnections " device(s) disconnected.`nLast Time: " lastDisconnectionTime, "Device Disconnected", 1)
    }

    ; Update tray icon tooltip with totals if any events were found
    if (newConnections > 0 || newDisconnections > 0) {
        SetIconTip()
    }

    isProcessing := false
}

; Set initial tray icon tooltip
SetIconTip()

; Create tray menu
A_TrayMenu.Add()
A_TrayMenu.Add("Clear Counters", ClearCounters)
A_TrayMenu.Add()

; Function to clear connection/disconnection counters
ClearCounters(*) {
    global totalConnections, totalDisconnections, lastConnectionTime, lastDisconnectionTime
    totalConnections := 0
    totalDisconnections := 0
    lastConnectionTime := "N/A"
    lastDisconnectionTime := "N/A"
    SetIconTip()
}

; Set up event monitoring
SetTimer(CheckDeviceEvents, 3000)

; Add cleanup handler for WMI resources
Cleanup(*) {
    global wmi, events
    try {
        events := ""
        wmi := ""
    }
}
OnExit(Cleanup)