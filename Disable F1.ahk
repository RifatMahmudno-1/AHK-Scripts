; This script was created to help one of my friends whose faulty keyboard kept sending accidental F1 keypresses
; This script disables the physical F1 key while still allowing it to be triggered via a custom hotkey (Ctrl + Alt + 1).


#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Trigger F1 with Ctrl + Alt + 1
^!1:: SendInput("{F1}")

; Suppress physical F1
$F1:: Return

A_IconTip := "Physical F1 Key Disabled`nPress Ctrl + Alt + 1 to trigger F1"