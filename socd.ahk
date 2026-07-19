#NoEnv                       ; 피해야 할 환경 변수 검사를 생략하여 실행 속도 향상
#MaxHotkeysPerInterval 99000000 ; 단시간 내 과도한 키 입력 시 경고창이 뜨는 것을 방지
#HotkeyInterval 99000000       ; 위 설정과 세트 (동시 입력 씹힘 방지)
KeyHistory 0                 ; 키 입력 이력 기록을 중지하여 CPU 오버헤드 제거
ListLines Off                ; 실행된 라인 로그 기록을 중지하여 연산 속도 극한으로 상승
Process, Priority, , H       ; 이 스크립트의 CPU 우선순위를 '높음(High)'으로 설정
SetBatchLines, -1            ; 스크립트 줄 간의 의도적인 대기 시간(10ms)을 없애고 즉시 실행
SetKeyDelay, -1, -1          ; 키 입력 사이의 지연 시간 제거 (가장 중요)
SetMouseDelay, -1            ; 마우스 입력 지연 시간 제거
SetDefaultMouseSpeed, 0      ; 마우스 이동 속도를 즉시 이동으로 설정
SetWinDelay, -1              ; 창 제어 관련 지연 시간 제거
SetControlDelay, -1          ; 컨트롤 제어 관련 지연 시간 제거
SendMode Input
#UseHook On            ; 윈도우 훅을 강제로 사용하여 키 입력 감지 속도 일관성 유지
Critical               ; 스크립트 연산 중 다른 백그라운드 스레드가 끼어들지 못하게 차단
Thread, Interrupt, 0   ; 핫키가 실행되는 순간 즉시 최우선 순위로 처리 (인터럽트 지연 0) 
; 변수 초기화 (0: 떼짐, 1: 눌러짐)
global a_pressed := 0
global d_pressed := 0
global last_key := ""

return

;--------------------------------------------------------
; A 키 입력 처리
;--------------------------------------------------------
~$*a::
    if (a_pressed)
        return ; 키가 계속 눌려있는 상태(반복 입력)면 무시
    
    a_pressed := 1
    last_key := "a"
    
    if (d_pressed) {
        ; D가 눌려있는 상태에서 A를 누르면, D를 떼고 A를 입력
        SendInput {Blind}{d up}{a down}
    } else {
        SendInput {Blind}{a down}
    }
return

~$*a up::
    a_pressed := 0
    
    if (d_pressed) {
        ; A를 뗐을 때 여전히 D가 눌려있다면 D를 다시 입력
        SendInput {Blind}{a up}{d down}
    } else {
        SendInput {Blind}{a up}
    }
return

;--------------------------------------------------------
; D 키 입력 처리
;--------------------------------------------------------
~$*d::
    if (d_pressed)
        return ; 키가 계속 눌려있는 상태(반복 입력)면 무시
    
    d_pressed := 1
    last_key := "d"
    
    if (a_pressed) {
        ; A가 눌려있는 상태에서 D를 누르면, A를 떼고 D를 입력
        SendInput {Blind}{a up}{d down}
    } else {
        SendInput {Blind}{d down}
    }
return

~$*d up::
    d_pressed := 0
    
    if (a_pressed) {
        ; D를 뗐을 때 여전히 A가 눌려있다면 A를 다시 입력
        SendInput {Blind}{d up}{a down}
    } else {
        SendInput {Blind}{d up}
    }
return
