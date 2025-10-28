#SingleInstance Force
Persistent

; Create WMI objects for device monitoring
wmi := ComObjGet("winmgmts:")
events := wmi.ExecNotificationQuery("SELECT * FROM Win32_DeviceChangeEvent")

; Set up event monitoring
SetTimer(CheckDeviceEvents, 1000)

CheckDeviceEvents() {
    foundEventTypes := Map()

    loop {
        try {
            ; Check for pending WMI events
            eventType := events.NextEvent(1).EventType  ; 1ms timeout
            if (eventType = 2 || eventType = 3) {
                foundEventTypes[eventType] := true
            }
        }
        catch {
            break  ; No more events, exit loop
        }
    }

    ; Handle different event types - only show first event (prioritized)
    if (foundEventTypes.Has(2)) {
        ; Device connected/inserted
        TrayTip("A device has been connected.", "Device Connected", 1)
        ; SoundBeep(800, 120)
    }
    if (foundEventTypes.Has(3)) {
        ; Device disconnected/removed
        TrayTip("A device has been disconnected.", "Device Disconnected", 1)
        ; SoundBeep(400, 120)
    }
}

; TrayTip("Monitoring device events using WMI...", "Device Monitor Running", 1)
