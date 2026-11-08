
#NoEnv
#SingleInstance Force
SetBatchLines -1
ListLines Off

; ===== 설정 =====
ClickDutyCyclePercent := 7.354
ClickCycleMs := 35
; =================

DllCall("kernel32.dll\QueryPerformanceFrequency", "Int64*", freq)

IsRunning := false

*RButton::
    IsRunning := !IsRunning
    SetTimer, ClickLoop, % IsRunning ? ClickCycleMs : "Off"
return

F9::ExitApp

ClickLoop:
    Critical, On

    ; 실제 설정값을 기준으로 고정밀 클릭 유지 시간 계산
    holdTicks := freq * ClickCycleMs * ClickDutyCyclePercent / 100000

    ; 마우스 왼쪽 버튼 DOWN
    DllCall("user32.dll\mouse_event"
        , "UInt", 0x0002
        , "UInt", 0
        , "UInt", 0
        , "UInt", 0
        , "UPtr", 0)

    ; 고성능 카운터 기준으로 유지 시간 측정
    DllCall("kernel32.dll\QueryPerformanceCounter", "Int64*", now)
    target := now + holdTicks

    while (now < target)
        DllCall("kernel32.dll\QueryPerformanceCounter", "Int64*", now)

    ; 마우스 왼쪽 버튼 UP
    DllCall("user32.dll\mouse_event"
        , "UInt", 0x0004
        , "UInt", 0
        , "UInt", 0
        , "UInt", 0
        , "UPtr", 0)

    Critical, Off
return
