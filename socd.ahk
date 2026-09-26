#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook


; ============================================================
; A/D SOCD - Last Input Priority
;
; AutoHotkey v2
;
; Physical state:
;   physicalA
;   physicalD
;
; Output state:
;   activeDirection
;
; Direction values:
;   0 = None
;   1 = A
;   2 = D
;
; LIP:
;   마지막으로 발생한 Down 이벤트의 키가 우선권을 가진다.
;
; ============================================================


; ============================================================
; 성능 최적화
; ============================================================

; Send는 Input 모드 사용
; AHK v2의 기본값이지만 명시적으로 설정한다.
SendMode "Input"

; 키보드 Hook 강제 사용
#UseHook

; 키 입력 이력 비활성화
KeyHistory 0

; 실행 라인 기록 비활성화
ListLines false

; 짧은 시간 동안 발생하는 많은 Hotkey 입력에 대한
; 경고 기준을 사실상 제거한다.
A_HotkeyInterval := 99000000
A_MaxHotkeysPerInterval := 99000000

; 프로세스 우선순위를 High로 설정.
; 게임 등 CPU 부하가 높은 상황에서 hotkey/send 지연을
; 줄이는 데 도움이 될 수 있다.
ProcessSetPriority "High"

; 새로 실행되는 Thread가 즉시 interruptible하도록 한다.
;
; 게임 입력처럼 hotkey 응답성이 중요한 경우 유리하다.
Thread "Interrupt", 0


; ============================================================
; 상태 변수
; ============================================================

; Physical keyboard state
global physicalA := false
global physicalD := false


; ------------------------------------------------------------
; 현재 실제로 게임에 출력하고 있는 방향
;
; 0 = 없음
; 1 = A
; 2 = D
; ------------------------------------------------------------

global activeDirection := 0


; ------------------------------------------------------------
; 마지막 Down 이벤트 순서
;
; 요구사항에 따라 마지막 입력 순서를 명시적으로 추적한다.
; ------------------------------------------------------------

global lastDownSequence := 0

global lastDownA := 0
global lastDownD := 0


; ============================================================
; A DOWN
; ============================================================

$*a::
{
    HandleKeyDown(1)
}


; ============================================================
; A UP
; ============================================================

$*a up::
{
    HandleKeyUp(1)
}


; ============================================================
; D DOWN
; ============================================================

$*d::
{
    HandleKeyDown(2)
}


; ============================================================
; D UP
; ============================================================

$*d up::
{
    HandleKeyUp(2)
}


; ============================================================
; Physical Key DOWN 처리
; ============================================================

HandleKeyDown(direction)
{
    global physicalA
    global physicalD
    global activeDirection

    global lastDownSequence
    global lastDownA
    global lastDownD


    ; --------------------------------------------------------
    ; A
    ; --------------------------------------------------------

    if (direction = 1)
    {
        ; 이미 Physical Down이면 중복 Down 무시
        if physicalA
            return

        physicalA := true
    }

    ; --------------------------------------------------------
    ; D
    ; --------------------------------------------------------

    else
    {
        ; 이미 Physical Down이면 중복 Down 무시
        if physicalD
            return

        physicalD := true
    }


    ; --------------------------------------------------------
    ; 마지막 Down 순서 기록
    ; --------------------------------------------------------

    lastDownSequence += 1

    if (direction = 1)
        lastDownA := lastDownSequence
    else
        lastDownD := lastDownSequence


    ; --------------------------------------------------------
    ; Last Input Priority
    ;
    ; 방금 Down된 방향을 즉시 활성화한다.
    ; --------------------------------------------------------

    if (activeDirection != direction)
        ActivateDirection(direction)
}


; ============================================================
; Physical Key UP 처리
; ============================================================

HandleKeyUp(direction)
{
    global physicalA
    global physicalD
    global activeDirection


    ; --------------------------------------------------------
    ; A UP
    ; --------------------------------------------------------

    if (direction = 1)
    {
        ; 중복 Up 방지
        if !physicalA
            return

        physicalA := false
    }

    ; --------------------------------------------------------
    ; D UP
    ; --------------------------------------------------------

    else
    {
        ; 중복 Up 방지
        if !physicalD
            return

        physicalD := false
    }


    ; --------------------------------------------------------
    ; 현재 활성 방향이 아니라면
    ; Output에는 아무런 변화가 없다.
    ;
    ; 예:
    ;
    ; physicalA = true
    ; physicalD = true
    ; activeDirection = D
    ;
    ; A Up
    ;
    ; => D 출력 그대로 유지
    ; --------------------------------------------------------

    if (activeDirection != direction)
        return


    ; --------------------------------------------------------
    ; 현재 활성 방향 Release
    ; --------------------------------------------------------

    DeactivateDirection(direction)


    ; --------------------------------------------------------
    ; 반대 방향이 아직 Physical Down이면
    ; 즉시 다시 활성화
    ; --------------------------------------------------------

    if (direction = 1)
    {
        if physicalD
            ActivateDirection(2)
    }
    else
    {
        if physicalA
            ActivateDirection(1)
    }
}


; ============================================================
; 방향 활성화
;
; 전환 순서:
;
;   기존 방향 UP
;   ↓
;   새로운 방향 DOWN
;
; 절대로 두 방향을 동시에 Output Down 상태로 만들지 않는다.
; ============================================================

ActivateDirection(direction)
{
    global activeDirection


    ; 이미 같은 방향이면 아무것도 하지 않는다.
    if (activeDirection = direction)
        return


    ; --------------------------------------------------------
    ; 기존 방향 Release
    ; --------------------------------------------------------

    if (activeDirection != 0)
        DeactivateDirection(activeDirection)


    ; --------------------------------------------------------
    ; 새로운 방향 Press
    ; --------------------------------------------------------

    if (direction = 1)
        SendInput "{a down}"
    else
        SendInput "{d down}"


    activeDirection := direction
}


; ============================================================
; 방향 비활성화
; ============================================================

DeactivateDirection(direction)
{
    global activeDirection


    ; 현재 활성 방향이 아니면 아무것도 하지 않는다.
    if (activeDirection != direction)
        return


    if (direction = 1)
        SendInput "{a up}"
    else
        SendInput "{d up}"


    activeDirection := 0
}


; ============================================================
; 시작 시 Physical A/D 상태 확인
; ============================================================

InitializePhysicalState()
{
    global physicalA
    global physicalD
    global activeDirection

    global lastDownSequence
    global lastDownA
    global lastDownD


    ; --------------------------------------------------------
    ; 실제 Physical keyboard 상태 확인
    ; --------------------------------------------------------

    physicalA := GetKeyState("a", "P")
    physicalD := GetKeyState("d", "P")


    ; 상태 초기화
    activeDirection := 0

    lastDownSequence := 0
    lastDownA := 0
    lastDownD := 0


    ; --------------------------------------------------------
    ; A만 눌린 경우
    ; --------------------------------------------------------

    if physicalA && !physicalD
    {
        lastDownSequence := 1
        lastDownA := 1

        ActivateDirection(1)
        return
    }


    ; --------------------------------------------------------
    ; D만 눌린 경우
    ; --------------------------------------------------------

    if physicalD && !physicalA
    {
        lastDownSequence := 1
        lastDownD := 1

        ActivateDirection(2)
        return
    }


    ; --------------------------------------------------------
    ; A와 D가 모두 눌린 경우
    ;
    ; 스크립트가 시작되기 전에 발생한 실제 Down 순서는
    ; AHK가 알 수 없다.
    ;
    ; 따라서 A를 deterministic fallback으로 사용한다.
    ; --------------------------------------------------------

    if physicalA && physicalD
    {
        lastDownSequence := 1
        lastDownA := 1

        ActivateDirection(1)
    }
}


; ============================================================
; 모든 Output Release
;
; Script 종료 / Reload 시 stuck 방지
; ============================================================

ReleaseAllOutputs(*)
{
    global activeDirection
    global physicalA
    global physicalD


    ; --------------------------------------------------------
    ; 현재 활성 방향 Release
    ; --------------------------------------------------------

    if (activeDirection = 1)
        SendInput "{a up}"
    else if (activeDirection = 2)
        SendInput "{d up}"


    ; --------------------------------------------------------
    ; 최종 방어 Release
    ;
    ; 혹시 내부 상태와 실제 Output 상태가 불일치했더라도
    ; A/D를 모두 Up으로 만든다.
    ; --------------------------------------------------------

    SendInput "{a up}"
    SendInput "{d up}"


    ; --------------------------------------------------------
    ; 내부 상태 초기화
    ; --------------------------------------------------------

    activeDirection := 0
    physicalA := false
    physicalD := false
}


; ============================================================
; 초기화
; ============================================================

InitializePhysicalState()


; ============================================================
; 종료 / Reload 안전 처리
; ============================================================

OnExit(ReleaseAllOutputs)
