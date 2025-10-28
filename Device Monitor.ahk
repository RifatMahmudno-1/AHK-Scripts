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

; Set initial tray icon tooltip
A_IconTip := "Total Connection Events: 0`nTotal Disconnection Events: 0"

; Initialize counters
totalConnections := 0
totalDisconnections := 0

; Event type constants
DEVICE_ARRIVAL := 2
DEVICE_REMOVAL := 3

; Flag to prevent concurrent processing
isProcessing := false

CheckDeviceEvents() {
    global totalConnections, totalDisconnections, isProcessing

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
        TrayTip("A device has been connected.", "Device Connected", 1)
    }

    if (foundEventTypes.Has(DEVICE_REMOVAL)) {
        ; Device disconnected/removed
        totalDisconnections++
        TrayTip("A device has been disconnected.", "Device Disconnected", 1)
    }

    ; Update tray icon tooltip with totals if any events were found
    if (foundEventTypes.Count > 0) {
        A_IconTip := "Total Connection Events: " . totalConnections . "`nTotal Disconnection Events: " . totalDisconnections
    }

    isProcessing := false
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