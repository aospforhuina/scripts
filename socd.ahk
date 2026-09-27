; === 성능 및 지연 시간 극한 최적화 ===
#NoEnv                         ; 피해야 할 환경 변수 검사를 생략하여 실행 속도 향상
#MaxHotkeysPerInterval 99000000 ; 단시간 내 과도한 키 입력 시 경고창이 뜨는 것을 방지
#HotkeyInterval 99000000       ; 위 설정과 세트 (동시 입력 씹힘 방지)
KeyHistory 0                   ; 키 입력 이력 기록을 중지하여 CPU 오버헤드 제거
ListLines Off                  ; 실행된 라인 로그 기록을 중지하여 연산 속도 극한으로 상승
Process, Priority, , H         ; 이 스크립트의 CPU 우선순위를 '높음(High)'으로 설정
SetBatchLines, -1              ; 스크립트 줄 간의 의도적인 대기 시간(10ms)을 없애고 즉시 실행
SetKeyDelay, -1, -1            ; 키 입력 사이의 지연 시간 제거 (가장 중요)
SetMouseDelay, -1              ; 마우스 입력 지연 시간 제거
SetDefaultMouseSpeed, 0        ; 마우스 이동 속도를 즉시 이동으로 설정
SetWinDelay, -1                ; 창 제어 관련 지연 시간 제거
SetControlDelay, -1            ; 컨트롤 제어 관련 지연 시간 제거
SendMode Input
#UseHook On                    ; 윈도우 훅을 강제로 사용하여 키 입력 감지 속도 일관성 유지
Critical                       ; 스크립트 연산 중 다른 백그라운드 스레드가 끼어들지 못하게 차단
Thread, Interrupt, 0           ; 스레드 중단 지연 방지

; === Caps Lock 및 Shift/Ctrl/Alt 모디파이어 키 간섭 완벽 차단 ===
#InstallKeybdHook
SetStoreCapsLockMode, Off      ; Caps Lock 상태 자동 조작 차단 (Caps Lock 활성화 시 끊김 해결)
#MenuMaskKey vkFF              ; AHK 내부의 불필요한 Ctrl/Alt 신호 주입 방지
SetWorkingDir %A_ScriptDir%

; --- 변수 초기화 ---
a_down := false
d_down := false
last_key := ""
current_output := ""

; --- A 키 (가상 키 코드 vk41) ---
*a::
    if (a_down)
        return
    a_down := true
    last_key := "vk41"
    UpdateSOCD()
return

*a up::
    a_down := false
    UpdateSOCD()
return

; --- D 키 (가상 키 코드 vk44) ---
*d::
    if (d_down)
        return
    d_down := true
    last_key := "vk44"
    UpdateSOCD()
return

*d up::
    d_down := false
    UpdateSOCD()
return

; --- SOCD 상태 업데이트 함수 ---
UpdateSOCD() {
    global a_down, d_down, last_key, current_output
    
    target := ""
    
    if (a_down && d_down) {
        target := last_key
    } 
    else if (a_down) {
        target := "vk41"
    } else if (d_down) {
        target := "vk44"
    }
    
    if (target == current_output)
        return
        
    ; {Blind} + VK 코드로 모디파이어 키/Caps Lock을 유지하면서 딜레이 없이 Pure Signal 송신
    if (current_output != "") {
        SendInput, {Blind}{%current_output% up}
    }
    
    if (target != "") {
        SendInput, {Blind}{%target% down}
    }
    
    current_output := target
}

; --- 온/오프 토글 (F12) ---
F12::
    Suspend
    SoundBeep, 750, 100
return
