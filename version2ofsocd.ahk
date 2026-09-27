; ============================================================
;  SOCD — 마지막 입력 우선 (Last Input Priority) / A·D 전용
;  AutoHotkey v1.1.x
; ============================================================
#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 99000
SetBatchLines -1
ListLines Off

; ★① CapsLock 켜짐일 때 Send가 CapsLock을 껐다 켜는 동작을 완전히 끔
SetStoreCapsLockMode, Off

; ★② SendInput → SendEvent 로 교체
;    SendInput은 전송 직전 자기 키보드 훅을 내렸다 복구함
;    → 그 틈에 물리 A/D가 새어나가고, 전환 순간에 끊김이 생김
;    SendEvent는 훅을 계속 유지하므로 차단이 끊기지 않음
SendMode Event
SetKeyDelay, -1, 0          ; 키 사이 지연 0

#InputLevel 1

physA   := 0
physD   := 0
lastDir := ""
outA    := 0
outD    := 0

; ── A ───────────────────────────────────────────────
*$a::
    if (physA)                  ; 오토리핏 무시
        return
    physA := 1, lastDir := "A"
    Gosub, SOCD_Update
return

*$a Up::
    physA := 0
    Gosub, SOCD_Update
return

; ── D ───────────────────────────────────────────────
*$d::
    if (physD)
        return
    physD := 1, lastDir := "D"
    Gosub, SOCD_Update
return

*$d Up::
    physD := 0
    Gosub, SOCD_Update
return

; ── 핵심 로직 ────────────────────────────────────────
SOCD_Update:
    wantA := physA && (!physD || lastDir = "A")
    wantD := physD && (!physA || lastDir = "D")

    keys := ""
    if (wantA != outA) {
        outA := wantA
        keys .= wantA ? "{a down}" : "{a up}"
    }
    if (wantD != outD) {
        outD := wantD
        keys .= wantD ? "{d down}" : "{d up}"
    }

    ; ★③ 두 이벤트를 한 번의 호출로 묶어서 전송
    ;    {Blind} = 모디파이어를 건드리지 않음 + SetStoreCapsLockMode 우회
    ;    전환 시 "a up → d down" 순서가 한 묶음으로 나가므로 중립 프레임이 사라짐
    if (keys != "")
        SendEvent, % "{Blind}" keys
return

; ── 비정상 종료 시 키 눌림 방지 ────────────────────────
OnExit, Cleanup
Cleanup:
    SendEvent, {Blind}{a up}{d up}
return