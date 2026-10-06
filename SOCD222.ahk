;=============================================================
; AHK v1 - SOCD 클리너 (A/D) - 상시 후입력 우선 ・ 퍼포먼스 버전
;-------------------------------------------------------------
;  [필수 기능 - 그대로 유지]
;   1) 후입력 우선 : A 누른 채 D → D 작동, D 를 떼면 A 복귀 (대칭 동일)
;   2) 와일드카드  : Alt/Shift/Ctrl/Esc 등과 함께 눌러도 동작
;   3) 풀 후킹     : 물리 A/D 입력을 앱에 전달하지 않음
;   4) OnExit 클린업 : 종료/재시작 시 키 고정 방지
;-------------------------------------------------------------
;  [퍼포먼스]
;   1) ListLines, Off        : 줄 로깅 비용 제거 (지연 최대 요인)
;   2) 전환/복귀 시 업+다운을 한 번의 Send 로 합침 (API 1회)
;   3) 중복 Send 제거        : 이미 처리된 키는 재전송 안 함
;   4) 프로세스 우선순위 High : 지연 지터 감소 (불안하면 제거)
;=============================================================
#NoEnv
#Persistent
#SingleInstance, Force
ListLines, Off

SendMode Input                   ; Send = SendInput (내부 DllCall, 최저 지연)
SetKeyDelay, -1, -1
Process, Priority, , High        ; (선택) 지연 지터 감소

; ---- 상태 초기화 (자동실행부 = return 위쪽) ----
aHeld := false   ; A 가 가상(출력)으로 눌려 있는가
dHeld := false   ; D 가 가상(출력)으로 눌려 있는가
aPhys := false   ; A 가 물리적으로 눌려 있는가 (훅 이벤트 기반)
dPhys := false   ; D 가 물리적으로 눌려 있는가 (훅 이벤트 기반)

OnExit, Cleanup
return   ; ======== 자동실행부 끝 (핫키는 항상 아래) ========

; ================= A =================
*$a::                        ; 물리 A 다운
    Critical
    aPhys := true
    if (dPhys) {             ; D 물리 보유 중 → D 떼고 A (한 번에 전송)
        dHeld := false
        Send {Blind}{d up}{a down}
    } else {
        Send {Blind}{a down}
    }
    aHeld := true
return

*$a up::                     ; 물리 A 업
    Critical
    aPhys := false
    if (dPhys) {
        if (!dHeld) {        ; D 물리 보유 + D 비활성 → A 떼고 D 복귀
            aHeld := false
            Send {Blind}{a up}{d down}
            dHeld := true
        } else if (aHeld) {  ; D 활성 중이면 A 정리만
            aHeld := false
            Send {Blind}{a up}
        }
    } else if (aHeld) {      ; 단독 릴리즈
        aHeld := false
        Send {Blind}{a up}
    }
return

; ================= D =================
*$d::                        ; 물리 D 다운
    Critical
    dPhys := true
    if (aPhys) {             ; A 물리 보유 중 → A 떼고 D (한 번에 전송)
        aHeld := false
        Send {Blind}{a up}{d down}
    } else {
        Send {Blind}{d down}
    }
    dHeld := true
return

*$d up::                     ; 물리 D 업
    Critical
    dPhys := false
    if (aPhys) {
        if (!aHeld) {        ; A 물리 보유 + A 비활성 → D 떼고 A 복귀
            dHeld := false
            Send {Blind}{d up}{a down}
            aHeld := true
        } else if (dHeld) {  ; A 활성 중이면 D 정리만
            dHeld := false
            Send {Blind}{d up}
        }
    } else if (dHeld) {      ; 단독 릴리즈
        dHeld := false
        Send {Blind}{d up}
    }
return

; ================= 종료 처리 =================
Cleanup:
    Send {Blind}{a up}{d up}
ExitApp
return