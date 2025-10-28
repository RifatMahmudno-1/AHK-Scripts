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

    foundEventTypes := Map()

    loop {
        try {
            ; Check for pending WMI events
            eventType := events.NextEvent(10).EventType  ; 10ms timeout
            if (eventType = DEVICE_ARRIVAL || eventType = DEVICE_REMOVAL) {
                foundEventTypes[eventType] := true
            }
        }
        catch {
            break  ; No more events, exit loop
        }
    }

    ; Handle different event types - only show one notification per type
    if (foundEventTypes.Has(DEVICE_ARRIVAL)) {
        ; Device connected/inserted
        totalConnections++
        lastConnectionTime := FormatTime(A_Now, "yyyy-MMM-dd hh:mm:ss tt")
        TrayTip("A device has been connected.`nTime: " lastConnectionTime, "Device Connected", 1)
    }

    if (foundEventTypes.Has(DEVICE_REMOVAL)) {
        ; Device disconnected/removed
        totalDisconnections++
        lastDisconnectionTime := FormatTime(A_Now, "yyyy-MMM-dd hh:mm:ss tt")
        TrayTip("A device has been disconnected.`nTime: " lastDisconnectionTime, "Device Disconnected", 1)
    }

    ; Update tray icon tooltip with totals if any events were found
    if (foundEventTypes.Count > 0) {
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
SetTimer(CheckDeviceEvents, 1000)

; Add cleanup handler for WMI resources
Cleanup(*) {
    global wmi, events
    try {
        events := ""
        wmi := ""
    }
}
OnExit(Cleanup)