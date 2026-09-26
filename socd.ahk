
#Requires AutoHotkey v2.0

; ============================================================
; A/D SOCD - Last Input Priority
; Performance Optimized
;
; AutoHotkey v2 only
;
; Physical state:
;   physicalA
;   physicalD
;
; Output state:
;   activeDirection
;
; Last physical Down:
;   lastDownDirection
;
; A/D 이외의 키에는 아무런 SOCD 처리를 하지 않는다.
; ============================================================


; ============================================================
; 성능 / 입력 처리 설정
; ============================================================

; 핫키 스레드가 중복으로 동시에 실행되는 것을 방지한다.
#MaxThreads 1
#MaxThreadsPerHotkey 1
#MaxThreadsBuffer false

; SendEvent의 기본 KeyDelay / PressDuration 제거.
; 음수 값은 지연을 사용하지 않음을 의미한다.
SetKeyDelay(-1, -1)

; 키보드/마우스 Hook 사용.
; $ 핫키와 함께 물리 입력을 안정적으로 구분하는 데 사용된다.



; ============================================================
; 상태 변수
; ============================================================

global physicalA := false
global physicalD := false

; 현재 실제 출력 중인 방향.
; "A", "D", ""
global activeDirection := ""

; 마지막으로 발생한 유효한 Physical Down.
; "A", "D", ""
global lastDownDirection := ""


; ============================================================
; 초기 상태
; ============================================================

InitializeState()


; ============================================================
; A Down
;
; $:
; SendEvent()로 생성된 A Down이 다시 이 핫키를 호출하지
; 않도록 한다.
; ============================================================

$a::
{
    HandleKeyDown("A")
}


; ============================================================
; A Up
; ============================================================

$a Up::
{
    HandleKeyUp("A")
}


; ============================================================
; D Down
; ============================================================

$d::
{
    HandleKeyDown("D")
}


; ============================================================
; D Up
; ============================================================

$d Up::
{
    HandleKeyUp("D")
}


; ============================================================
; 초기 상태 확인
;
; 스크립트가 시작될 때 이미 눌려 있는 A/D를 확인한다.
;
; 시작 이전의 실제 Down 순서는 알 수 없으므로 둘 다 눌려
; 있는 특수한 경우 A를 초기 우선순위로 사용한다.
; ============================================================

InitializeState()
{
    global physicalA
    global physicalD
    global activeDirection
    global lastDownDirection

    physicalA := GetKeyState("a", "P")
    physicalD := GetKeyState("d", "P")

    if (physicalA)
    {
        lastDownDirection := "A"
    }
    else if (physicalD)
    {
        lastDownDirection := "D"
    }
    else
    {
        lastDownDirection := ""
    }

    if (physicalA && physicalD)
    {
        ; 시작 이전의 Down 순서를 알 수 없으므로
        ; 결정적인 초기값으로 A를 사용한다.
        activeDirection := "A"
        SendKeyDown("A")
    }
    else if (physicalA)
    {
        activeDirection := "A"
        SendKeyDown("A")
    }
    else if (physicalD)
    {
        activeDirection := "D"
        SendKeyDown("D")
    }
}


; ============================================================
; Physical Key Down
; ============================================================

HandleKeyDown(key)
{
    global physicalA
    global physicalD
    global activeDirection
    global lastDownDirection

    ; 입력 처리 중 다른 스레드가 상태를 변경하지 않도록 한다.
    Critical("On")

    ; --------------------------------------------------------
    ; 이미 눌린 키의 중복 Down은 무시한다.
    ; --------------------------------------------------------

    if (key = "A")
    {
        if (physicalA)
        {
            return
        }

        physicalA := true
    }
    else
    {
        ; 이 함수는 A/D만 호출하므로 D로 처리한다.
        if (physicalD)
        {
            return
        }

        physicalD := true
    }

    ; --------------------------------------------------------
    ; 새로운 Down이므로 LIP의 최신 입력으로 기록.
    ; --------------------------------------------------------

    lastDownDirection := key

    ; 이미 해당 방향이 활성화되어 있다면 아무 것도 하지 않는다.
    if (activeDirection = key)
    {
        return
    }

    ; --------------------------------------------------------
    ; 방향 전환
    ;
    ; 반드시:
    ;
    ; 기존 방향 Up
    ; 새 방향 Down
    ;
    ; 순서를 유지한다.
    ; --------------------------------------------------------

    if (activeDirection = "A")
    {
        SendKeyUp("A")
    }
    else if (activeDirection = "D")
    {
        SendKeyUp("D")
    }

    SendKeyDown(key)
    activeDirection := key
}


; ============================================================
; Physical Key Up
; ============================================================

HandleKeyUp(key)
{
    global physicalA
    global physicalD
    global activeDirection

    Critical("On")

    ; --------------------------------------------------------
    ; Physical 상태 변경
    ; --------------------------------------------------------

    if (key = "A")
    {
        ; 이미 Up이면 중복 Up이므로 무시.
        if (!physicalA)
        {
            return
        }

        physicalA := false
    }
    else
    {
        if (!physicalD)
        {
            return
        }

        physicalD := false
    }

    ; --------------------------------------------------------
    ; 현재 활성 방향이 아니라면 출력에 아무런 영향을 주지
    ; 않는다.
    ; --------------------------------------------------------

    if (activeDirection != key)
    {
        return
    }

    ; --------------------------------------------------------
    ; 현재 활성 방향 Release
    ; --------------------------------------------------------

    SendKeyUp(key)
    activeDirection := ""

    ; --------------------------------------------------------
    ; 반대 키가 여전히 Physical Down이면 즉시 복귀.
    ; --------------------------------------------------------

    if (key = "A")
    {
        if (physicalD)
        {
            SendKeyDown("D")
            activeDirection := "D"
        }
    }
    else
    {
        if (physicalA)
        {
            SendKeyDown("A")
            activeDirection := "A"
        }
    }
}


; ============================================================
; 실제 A/D Down 출력
; ============================================================

SendKeyDown(key)
{
    if (key = "A")
    {
        SendEvent("{a down}")
    }
    else
    {
        SendEvent("{d down}")
    }
}


; ============================================================
; 실제 A/D Up 출력
; ============================================================

SendKeyUp(key)
{
    if (key = "A")
    {
        SendEvent("{a up}")
    }
    else
    {
        SendEvent("{d up}")
    }
}


; ============================================================
; 안전한 전체 Release
;
; Reload / Exit 때 호출된다.
; ============================================================

ReleaseAllOutputs()
{
    global physicalA
    global physicalD
    global activeDirection
    global lastDownDirection

    Critical("On")

    ; 현재 활성 출력부터 해제한다.
    if (activeDirection = "A")
    {
        SendKeyUp("A")
    }
    else if (activeDirection = "D")
    {
        SendKeyUp("D")
    }

    ; 내부 상태가 예상과 달라졌더라도 stuck 방지를 위해
    ; A/D 양쪽에 Up을 한 번 더 보낸다.
    SendKeyUp("A")
    SendKeyUp("D")

    physicalA := false
    physicalD := false
    activeDirection := ""
    lastDownDirection := ""
}


; ============================================================
; Script 종료 / Reload
; ============================================================

OnExit(HandleExit)


HandleExit(ExitReason, ExitCode)
{
    ReleaseAllOutputs()
}

