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

; Set initial tray icon tooltip
A_IconTip := "Total Connection Events: 0`nTotal Disconnection Events: 0"

CheckDeviceEvents() {
    global totalConnections, totalDisconnections, events
    foundEventTypes := Map()

    loop {
        try {
            ; Check for pending WMI events
            eventType := events.NextEvent(100).EventType  ; 100ms timeout
            if (eventType = 2 || eventType = 3) {
                foundEventTypes[eventType] := true
            }
        }
        catch {
            break  ; No more events, exit loop
        }
    }

    ; Handle different event types - only show one notification per type
    if (foundEventTypes.Has(2)) {
        ; Device connected/inserted
        totalConnections++
        TrayTip("A device has been connected.", "Device Connected", 1)
    }

    if (foundEventTypes.Has(3)) {
        ; Device disconnected/removed
        totalDisconnections++
        TrayTip("A device has been disconnected.", "Device Disconnected", 1)
    }

    ; Update tray icon tooltip with totals if any events were found
    if (foundEventTypes.Count > 0) {
        A_IconTip := "Total Connection Events: " . totalConnections . "`nTotal Disconnection Events: " . totalDisconnections
    }
}

; Set up event monitoring
SetTimer(CheckDeviceEvents, 1000)