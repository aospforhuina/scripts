#NoEnv
#SingleInstance Force
SetBatchLines -1
ListLines Off

; ===== 설정 =====
ClickDutyCyclePercent := 7.354
ClickCycleMs :=  CycleMs := 55
; =================

DllCall("kernel32.dll\QueryPerformanceFrequency", "Int64*", freq)

IsRunning := false

*RButton::
    IsRunning := !IsRunning
    SetTimer ClickLoop, % IsRunning ? ClickCycleMs : "Off"
return

F9::ExitApp

ClickLoop:
    holdMs := Round(ClickCycleMs * ClickDutyCyclePercent / 100)
    
    DllCall("user32.dll\mouse_event", "UInt", 0x0002, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0)
    
    DllCall("kernel32.dll\QueryPerformanceCounter", "Int64*", now)
    target := now + (holdMs * freq / 1000)
    while (now < target)
        DllCall("kernel32.dll\QueryPerformanceCounter", "Int64*", now)
    
    DllCall("user32.dll\mouse_event", "UInt", 0x0004, "UInt", 0, "UInt", 0, "UInt", 0, "UPtr", 0)
return