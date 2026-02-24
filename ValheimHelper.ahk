; ValheimHelper
; Tobias Engwall
; 2026-02-13

; ╔══════════════╗
; ║ Initializing ║
; ╚══════════════╝
#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
#UseHook True   ; Listen directly to the inputs, not through Windows


if !A_IsAdmin
{
    ;MsgBox "Valheim kräver att scriptet körs som Admin.`n`nScriptet kommer nu startas om.", "Admin krävs", "Icon!"
    Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}





























; ╔═══════════════════════╗
; ║	    GUI / Settings    ║
; ╟┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄╢
; ║ - Globals             ║
; ║ - Load config         ║
; ║ - Save config         ║
; ║ - Key capture? ----   ║
; ║ - GUI design          ║
; ║ - Statustext <<OFF    ║
; ║ - Key capture         ║
; ║                       ║
; ╚═══════════════════════╝


; ━━━━━━━━━━ Config path in Documents ━━━━━━━━━━
configFolder := A_MyDocuments "\ValheimHelper"
if !DirExist(configFolder)
    DirCreate(configFolder)
global configFile := configFolder "\settings.ini"

global cfgGui := 0
global lblStatus := 0

global checkbox_roll := 0
global keybind_roll := 0
global btnBind_roll := 0

global checkbox_scroll := 0
global checkboxes_scroll_x8_status := []

global checkbox_eat := 0
global dropdown_slot1 := 0
global dropdown_slot2 := 0
global dropdown_slot3 := 0
global checkbox_eat_block := 0
global keybind_eat := 0
global btnBind_eat := 0

global checkbox_quickshield := 0
global dropdown_shield := 0
global keybind_shield := 0
global btnBind_shield := 0

global keybind_config := 0
global btnBind_config := 0










; ━━━━━━━━━━ Load config from INI ━━━━━━━━━━
global cfg := Map(
    "checkbox_roll",      IniRead(configFile, "Settings", "checkbox_roll", 1),
    "keybind_roll",       IniRead(configFile, "Settings", "keybind_roll", "XButton2"),

    "checkbox_scroll",    IniRead(configFile, "Settings", "checkbox_scroll", 1),
    ; 8-bit mask: bit0=slot1 ... bit7=slot8
    ; 255 = all 8 slots checked
    "scroll_slots_mask",  IniRead(configFile, "Settings", "scroll_slots_mask", 255),

    "checkbox_eat",       IniRead(configFile, "Settings", "checkbox_eat", 1),
    "dropdown_slot1",     IniRead(configFile, "Settings", "dropdown_slot1", 5),
    "dropdown_slot2",     IniRead(configFile, "Settings", "dropdown_slot2", 6),
    "dropdown_slot3",     IniRead(configFile, "Settings", "dropdown_slot3", 1),
    "checkbox_eat_block", IniRead(configFile, "Settings", "checkbox_eat_block", 0),
    "keybind_eat",        IniRead(configFile, "Settings", "keybind_eat", "XButton1"),

    "checkbox_quickshield",IniRead(configFile, "Settings", "checkbox_quickshield", 1),
    "dropdown_shield",     IniRead(configFile, "Settings", "dropdown_shield", 8),
    "keybind_shield",      IniRead(configFile, "Settings", "keybind_shield", "Q"),

    "keybind_config",     IniRead(configFile, "Settings", "keybind_config", "F11")
)










; ━━━━━━━━━━ Save config to INI ━━━━━━━━━━
ApplySettings(*)
{
    global cfg, configFile
    global checkbox_roll, keybind_roll
    global checkbox_scroll, checkboxes_scroll_x8_status
    global checkbox_eat, dropdown_slot1, dropdown_slot2, dropdown_slot3, checkbox_eat_block, keybind_eat
    global checkbox_quickshield, dropdown_shield, keybind_shield
    global keybind_config

    cfg["checkbox_roll"] := checkbox_roll.Value
    cfg["keybind_roll"] :=  keybind_roll.Value

    cfg["checkbox_scroll"] := checkbox_scroll.Value
    ; Step through the status list and bitwise extract 8-bit value
    mask := 0
    Loop 8
    {
        if (checkboxes_scroll_x8_status[A_Index].Value)
            mask |= (1 << (A_Index - 1))
    }
    cfg["scroll_slots_mask"] :=   mask

    cfg["checkbox_eat"] :=        checkbox_eat.Value
    cfg["dropdown_slot1"] :=      dropdown_slot1.Value
    cfg["dropdown_slot2"] :=      dropdown_slot2.Value
    cfg["dropdown_slot3"] :=      dropdown_slot3.Value
    cfg["checkbox_eat_block"] :=  checkbox_eat_block.Value
    cfg["keybind_eat"] :=         keybind_eat.Value

    cfg["checkbox_quickshield"] := checkbox_quickshield.Value
    cfg["dropdown_shield"] :=      dropdown_shield.Value
    cfg["keybind_shield"] :=       keybind_shield.Value

    cfg["keybind_config"] :=      keybind_config.Value


    IniWrite(cfg["checkbox_roll"],      configFile, "Settings", "checkbox_roll")
    IniWrite(cfg["keybind_roll"],       configFile, "Settings", "keybind_roll")

    IniWrite(cfg["checkbox_scroll"],    configFile, "Settings", "checkbox_scroll")
    IniWrite(cfg["scroll_slots_mask"],  configFile, "Settings", "scroll_slots_mask")

    IniWrite(cfg["checkbox_eat"],       configFile, "Settings", "checkbox_eat")
    IniWrite(cfg["dropdown_slot1"],     configFile, "Settings", "dropdown_slot1")
    IniWrite(cfg["dropdown_slot2"],     configFile, "Settings", "dropdown_slot2")
    IniWrite(cfg["dropdown_slot3"],     configFile, "Settings", "dropdown_slot3")
    IniWrite(cfg["checkbox_eat_block"], configFile, "Settings", "checkbox_eat_block")
    IniWrite(cfg["keybind_eat"],        configFile, "Settings", "keybind_eat")

    IniWrite(cfg["checkbox_quickshield"],configFile, "Settings", "checkbox_quickshield")
    IniWrite(cfg["dropdown_shield"],     configFile, "Settings", "dropdown_shield")
    IniWrite(cfg["keybind_shield"],      configFile, "Settings", "keybind_shield")

    IniWrite(cfg["keybind_config"],     configFile, "Settings", "keybind_config")

    ; uppdatera config-hotkey live
    SetConfigHotkey(cfg["keybind_config"])

    UpdateStatusText("Saved.")
}










; ━━━━━━━━━━ Key capture state ━━━━━━━━━━
global captureActive := false
global captureTargetEdit := 0         ; vilket Edit-fält vi fyller (keybind_roll / keybind_config)
global captureTargetCfgKey := ""      ; vilken cfg-nyckel vi sparar i ("keybind_roll" / "keybind_config")

global mouseHotkeys := ["*LButton","*RButton","*MButton","*XButton1","*XButton2","*WheelUp","*WheelDown"]
global kbHotkeys := []
InitKeyboardHotkeys()

InitKeyboardHotkeys()
{
    global kbHotkeys
    keys := []

    ; A-Z
    Loop 26
        keys.Push("*" Chr(64 + A_Index))

    ; 0-9 top row
    keys.Push("*0")
    Loop 9
        keys.Push("*" A_Index)

    ; F1-F12
    Loop 12
        keys.Push("*F" A_Index)

    ; Common keys
    for k in ["*Esc","*Tab","*Enter","*Space","*Backspace","*Delete","*Insert"
            ,"*Home","*End","*PgUp","*PgDn","*Up","*Down","*Left","*Right"
            ,"*CapsLock"]
        keys.Push(k)

    ; Numpad
    for k in ["*Numpad0","*Numpad1","*Numpad2","*Numpad3","*Numpad4","*Numpad5","*Numpad6","*Numpad7","*Numpad8","*Numpad9"
            ,"*NumpadDot","*NumpadAdd","*NumpadSub","*NumpadMult","*NumpadDiv","*NumpadEnter"]
        keys.Push(k)

    kbHotkeys := keys
}










; ━━━━━━━━━━ GUI design ━━━━━━━━━━

global currentConfigHotkey := ""
SetConfigHotkey(cfg["keybind_config"])

SetConfigHotkey(newKey)
{
    global currentConfigHotkey

    ; stäng av tidigare om den fanns
    if (currentConfigHotkey != "")
        try Hotkey("*" currentConfigHotkey, "Off")

    currentConfigHotkey := newKey

    ; slå på ny
    Hotkey "*" currentConfigHotkey, OpenConfig, "On"
}

OpenConfig(*)
{
    global cfgGui, cfg
    global checkbox_roll, keybind_roll
    global checkbox_scroll, checkboxes_scroll_x8_status
    global checkbox_eat, dropdown_slot1, dropdown_slot2, dropdown_slot3, checkbox_eat_block, keybind_eat
    global checkbox_quickshield, dropdown_shield, keybind_shield
    global keybind_config
    global lblStatus

    if IsObject(cfgGui)
    {
        ; sync values
        checkbox_roll.Value := cfg["checkbox_roll"]
        keybind_roll.Value := cfg["keybind_roll"]

        checkbox_scroll.Value := cfg["checkbox_scroll"]
        ; Step through the 8-bit mask and bitwise extract the saved checkbox states
        mask := cfg["scroll_slots_mask"]
        Loop 8
            checkboxes_scroll_x8_status[A_Index].Value := (mask >> (A_Index - 1)) & 1

        checkbox_quickshield.Value := cfg["checkbox_quickshield"]
        dropdown_shield.Choose(Integer(cfg["dropdown_shield"]))
        keybind_shield.Value := cfg["keybind_shield"]

        checkbox_eat.Value := cfg["checkbox_eat"]
        dropdown_slot1.Choose(Integer(cfg["dropdown_slot1"]))
        dropdown_slot2.Choose(Integer(cfg["dropdown_slot2"]))
        dropdown_slot3.Choose(Integer(cfg["dropdown_slot3"]))
        checkbox_eat_block.Value := cfg["checkbox_eat_block"]
        keybind_eat.Value := cfg["keybind_eat"]

        keybind_config.Value := cfg["keybind_config"]

        UpdateStatusText("Loaded.")
        cfgGui.Show("AutoSize Center")
        return
    }

    cfgGui := Gui(, "ValheimHelper - Settings")
    cfgGui.BackColor := "ffffff"
    cfgGui.MarginX := 50
    cfgGui.MarginY := 35
    cfgGui.SetFont("s11", "Segoe UI")

    cfgGui.SetFont("s24 Bold", "Segoe UI")
    cfgGui.AddText("Center w420 c8a2727", "ValheimHelper Settings")
    cfgGui.SetFont("s11", "Segoe UI")

    ; =========================
    ; One-click rolling
    ; =========================
    cfgGui.SetFont("s11 Bold", "Segoe UI")
    cfgGui.AddText("Center w420 cBBBBBB y+14", "One-click rolling")

    cfgGui.SetFont("s11 Norm", "Segoe UI")
    checkbox_roll := cfgGui.AddCheckbox("w420 h20 y+10 Checked" cfg["checkbox_roll"], "Enable one-click rolling")
    keybind_roll := cfgGui.AddEdit("w150 ReadOnly y+15", cfg["keybind_roll"])
    btnBind_roll := cfgGui.AddButton("x+10 yp-4 w140", "Bind…")
    btnBind_roll.OnEvent("Click", (*) => StartCaptureFor("keybind_roll", keybind_roll))

    cfgGui.AddText("xs w420 h2 y+18 BackgroundBBBBBB")

    ; =========================
    ; Hotbar scrolling
    ; =========================
    cfgGui.SetFont("s10 Bold", "Segoe UI")
    cfgGui.AddText("Center w420 cBBBBBB y+5", "Hotbar Scrolling")
    
    cfgGui.SetFont("s11 Norm", "Segoe UI")
    checkbox_scroll := cfgGui.AddCheckbox("w420 h24 y+10 Checked" cfg["checkbox_scroll"], "Enable hotbar scrolling")

    ; Rad med 8 checkboxar (1..8)
    cfgGui.AddText("y+15", "Scroll slots:")
    checkboxes_scroll_x8_status := []

    mask := cfg["scroll_slots_mask"]

    ; Stepping through the scroll slot list, check saved status and draw to the right...
    Loop 8
    {
        i := A_Index
        checked := (mask >> (i-1)) & 1

        opt := (i=1) ? "xs y+2" : "x+5"
        cb := cfgGui.AddCheckbox(opt " Checked" checked, "" i)
        checkboxes_scroll_x8_status.Push(cb)
    }

    cfgGui.AddText("xs w420 h2 y+18 BackgroundBBBBBB")

    ; ==============
    ; One-click eating
    ; ==============
    cfgGui.SetFont("s11 Bold", "Segoe UI")
    cfgGui.AddText("Center w420 cBBBBBB y+5", "One-click eating")

    cfgGui.SetFont("s11 Norm", "Segoe UI")
    checkbox_eat := cfgGui.AddCheckbox("w420 h20 y+10 Checked" cfg["checkbox_eat"], "Enable one-click eating")

    cfgGui.AddText("xs y+15 Section w100", "Food 1 slot:")
    dropdown_slot1 := cfgGui.AddDropDownList("xs w100 Choose" cfg["dropdown_slot1"] " y+6"
        , ["1","2","3","4","5","6","7","8"])

    cfgGui.AddText("x+20 ys w100", "Food 2 slot:")
    dropdown_slot2 := cfgGui.AddDropDownList("xp w100 Choose" cfg["dropdown_slot2"] " y+6"
        , ["None","1","2","3","4","5","6","7","8"])

    cfgGui.AddText("x+20 ys w100", "Food 3 slot:")
    dropdown_slot3 := cfgGui.AddDropDownList("xp w100 Choose" cfg["dropdown_slot3"] " y+6"
        , ["None","1","2","3","4","5","6","7","8"])
    
    cfgGui.SetFont("s11 Norm", "Segoe UI")
    checkbox_eat_block := cfgGui.AddCheckbox("xs w420 h20 y+10 Checked" cfg["checkbox_eat_block"], "Block keyboard number buttons")

    keybind_eat := cfgGui.AddEdit("w150 ReadOnly y+18", cfg["keybind_eat"])
    btnBind_eat := cfgGui.AddButton("x+10 yp-4 w140", "Bind…")
    btnBind_eat.OnEvent("Click", (*) => StartCaptureFor("keybind_eat", keybind_eat))

    cfgGui.AddText("xs w420 h2 y+18 BackgroundBBBBBB")

    ; =========================
    ; Quick-shield
    ; =========================
    cfgGui.SetFont("s10 Bold", "Segoe UI")
    cfgGui.AddText("xs Center w420 cBBBBBB y+5", "Quick-shield")
    
    cfgGui.SetFont("s11 Norm", "Segoe UI")
    checkbox_quickshield := cfgGui.AddCheckbox("w420 h24 y+10 Checked" cfg["checkbox_quickshield"], "Enable quick-shield")

    cfgGui.AddText("w100 y+12 Section", "Shield slot:")
    dropdown_shield := cfgGui.AddDropDownList("w100 Choose" cfg["dropdown_shield"] " y+6"
        , ["1","2","3","4","5","6","7","8"])

    keybind_shield := cfgGui.AddEdit("Center w150 ReadOnly y+20", cfg["keybind_shield"])
    btnBind_shield := cfgGui.AddButton("x+10 yp-4 w140", "Bind…")
    btnBind_shield.OnEvent("Click", (*) => StartCaptureFor("keybind_shield", keybind_shield))

    cfgGui.AddText("xs w420 h2 y+18 BackgroundBBBBBB")
    
    ; =========================
    ; ValheimHelper hotkey
    ; =========================
    cfgGui.SetFont("s10 Bold", "Segoe UI")
    cfgGui.AddText("Center w420 cBBBBBB y+5", "ValheimHelper hotkey")
    cfgGui.SetFont("s11 Norm", "Segoe UI")

    keybind_config := cfgGui.AddEdit("Center w150 ReadOnly y+20", cfg["keybind_config"])
    btnBind_config := cfgGui.AddButton("x+10 yp-4 w140", "Bind…")
    btnBind_config.OnEvent("Click", (*) => StartCaptureFor("keybind_config", keybind_config))

    cfgGui.AddText("xs w420 h2 y+18 BackgroundBBBBBB")

    ; =========================
    ; Apply
    ; ========================= 
    btnApply := cfgGui.AddButton("Center w180 x170 y+22 Default", "Apply")
    btnApply.OnEvent("Click", ApplySettings)

    cfgGui.Show("AutoSize Center")
}



UpdateStatusText(msg := "")
{
    global cfg, lblStatus
    if !IsObject(lblStatus)
        return

    lblStatus.Value := (
        msg
        (msg != "" ? "  |  " : "")
        "roll=" (cfg["checkbox_roll"] ? "ON" : "OFF")
        "  scroll=" (cfg["checkbox_scroll"] ? "ON" : "OFF")
        "  quickshield=" (cfg["checkbox_quickshield"] ? "ON" : "OFF")
        "  rollKey=" cfg["keybind_roll"]
        "  cfgKey=" cfg["keybind_config"]
    )
}










; ━━━━━━━━━━ Key capture (for binding) ━━━━━━━━━━
; Parameter 1 = The config key that we're capturing for
; Parameter 2 = The GUI box that will show the new key
StartCaptureFor(cfgKey, targetEditCtrl)
{
    global captureActive, captureTargetEdit, captureTargetCfgKey, lblStatus

    if captureActive
        return

    captureActive := true
    captureTargetCfgKey := cfgKey
    captureTargetEdit := targetEditCtrl

    UpdateStatusText("Listening… (Esc cancels)")


    global mouseHotkeys, kbHotkeys

    ; Create hotkeys for every button in our lists
    ; These work like interrupts and (the first one pressed) will run CaptureFromHotkey
    for hk in mouseHotkeys
        Hotkey hk, CaptureFromHotkey, "On"
    for hk in kbHotkeys
        Hotkey hk, CaptureFromHotkey, "On"
}



; Launched by first keypress (interrupt) during binding
; 
CaptureFromHotkey(thisHotkey)
{
    global cfg, captureTargetEdit, captureTargetCfgKey

    ; Removes * from the start
    name := RegExReplace(thisHotkey, "^\*")

    if (name = "Esc")
    {
        UpdateStatusText("Canceled.")
        StopCapture()
        return
    }

    bind := BuildBindString(name)

    ; store in cfg + update the correct edit field
    cfg[captureTargetCfgKey] := bind
    captureTargetEdit.Value := bind

    UpdateStatusText("Captured: " bind)
    StopCapture()
}



; Makes it possible to bind with modifiers
; .= is like += for strings. Each modifier pressed gets their syntax added to the output
BuildBindString(keyName)
{
    modifier := ""
    if GetKeyState("Ctrl","P")
        modifier .= "^"
    if GetKeyState("Alt","P")
        modifier .= "!"
    if GetKeyState("Shift","P")
        modifier .= "+"
    if (GetKeyState("LWin","P") || GetKeyState("RWin","P"))
        modifier .= "#"
    return modifier . keyName
}


; Turns off all temporary hotkeys
StopCapture()
{
    global captureActive, mouseHotkeys, kbHotkeys

    for hk in mouseHotkeys
        Hotkey hk, "Off"
    for hk in kbHotkeys
        Hotkey hk, "Off"

    captureActive := false

    ; Reactivates configurated hotkeys
    SetRollHotkey(cfg["keybind_roll"])
    SetConfigHotkey(cfg["keybind_config"])
}































; Only hijack input while in-game
#HotIf WinActive("ahk_exe valheim.exe")

; For updating dynamic keybindings
IsValheimActive(*)
{
    return WinActive("ahk_exe valheim.exe")
}



; ╔════════════════╗
; ║ One-click roll ║
; ╚════════════════╝
; bindas dynamiskt från cfg["keybind_roll"]
; Vi skapar en hotkey varje gång scriptet startar, och när du klickar Apply.

global currentRollHotkey := ""

SetRollHotkey(cfg["keybind_roll"])

SetRollHotkey(newKey)
{
    global currentRollHotkey

    ; Making sure the new hotkey only applies when Valheim is active. 
    ; When this function gets called from outside the first HotIf, the new hotkey is global
    HotIf(IsValheimActive)

    ; Remove the old hotkey
    if (currentRollHotkey != "")
        try Hotkey("*" currentRollHotkey, "Off")

    ; Bind the new hotkey
    currentRollHotkey := newKey
    Hotkey "*" currentRollHotkey, DoRoll, "On"

    HotIf()
}

DoRoll(*)
{
    global cfg
    if !cfg["checkbox_roll"]
        return

    Send "{RButton down}"
    Sleep 30
    Send "{Space down}"
    Sleep 30
    Send "{Space up}"
    Sleep 30
    Send "{RButton up}"
    Sleep 30
}



; ╔═══════════════════╗
; ║ Hotbar scrolling  ║
; ╚═══════════════════╝

global previousSlot := 0
global currentSlot := 1

; Scrolling right
$WheelUp::
{
    global cfg, currentSlot
    if !cfg["checkbox_scroll"]
        return

    n := FindNextEnabledSlot(currentSlot, -1)
    if (n != 0)
        SetSlot(n)
}

; Scrolling left
$WheelDown::
{
    global cfg, currentSlot
    if !cfg["checkbox_scroll"]
        return

    n := FindNextEnabledSlot(currentSlot, +1)
    if (n != 0)
        SetSlot(n)
}



; Check the saved checkbox status for next selected slot
FindNextEnabledSlot(fromSlot, dir)
{
    slot := fromSlot
    Loop 8
    {
        slot += dir
        if (slot < 1)
            slot := 8
        else if (slot > 8)
            slot := 1

        if IsScrollSlotEnabled(slot)
            return slot
    }
    return 0
}

; Checking the 8-bit mask bitwise for 1 or 0 in the selected slot
IsScrollSlotEnabled(slot)
{
    global cfg
    mask := cfg["scroll_slots_mask"]
    return ((mask >> (slot - 1)) & 1) = 1
}



; Pressing the numbers should still work
$1::SetSlot(1)
$2::SetSlot(2)
$3::SetSlot(3)
$4::SetSlot(4)
$5::SetSlot(5)
$6::SetSlot(6)
$7::SetSlot(7)
$8::SetSlot(8)

SetSlot(n)
{
    global currentSlot, previousSlot

    previousSlot := currentSlot
    currentSlot := n

    ; Check if the new slot is blocked from mouse/keyboard
    if !eating_blockcheck(currentSlot)
    {
        Send "{" currentSlot " down}"
        Sleep 50
        Send "{" currentSlot " up}"
        Sleep 50
    }
}



; ╔══════════════════╗
; ║ One-click eating ║
; ╚══════════════════╝

global currentEatHotkey := ""

SetEatHotkey(cfg["keybind_eat"])

SetEatHotkey(newKey)
{
    global currentEatHotkey

    ; Making sure the new hotkey only applies when Valheim is active. 
    ; When this function gets called from outside the first HotIf, the new hotkey is global
    HotIf(IsValheimActive)

    ; Remove the old hotkey
    if (currentEatHotkey != "")
        try Hotkey("*" currentEatHotkey, "Off")

    ; Bind the new hotkey
    currentEatHotkey := newKey
    Hotkey "*" currentEatHotkey, oneclickeating, "On"

    HotIf()
}

oneclickeating(*)
{
    global cfg

    if !cfg["checkbox_eat"]
        return

    eat_slots := [cfg["dropdown_slot1"], cfg["dropdown_slot2"]-1, cfg["dropdown_slot3"]-1]

    for slot in eat_slots
    {
        if (slot = 0) ; if "None"
            continue

        Send "{" slot " down}"
        Sleep 50
        Send "{" slot " up}"
        Sleep 50
    }
}

eating_blockcheck(currentSlot)
{
    global cfg

    if !cfg["checkbox_eat_block"]
        return

    eat_slots := [cfg["dropdown_slot1"], cfg["dropdown_slot2"]-1, cfg["dropdown_slot3"]-1]

    for blockedSlot in eat_slots
    {
        if (blockedSlot = 0) ; if "None"
            continue

        ; if the new slot matches any of the blocked ones...
        else if (currentSlot = blockedSlot)
            return True
    }
    return False
}




; ╔══════════════╗
; ║ Quick-shield ║
; ╚══════════════╝

global currentShieldHotkey := ""

SetShieldHotkey(cfg["keybind_shield"])

SetShieldHotkey(newKey)
{
    global currentShieldHotkey

    ; Making sure the new hotkey only applies when Valheim is active. 
    ; When this function gets called from outside the first HotIf, the new hotkey is global
    HotIf(IsValheimActive)

    ; Remove the old hotkey
    if (currentShieldHotkey != "")
        try Hotkey("*" currentShieldHotkey, "Off")

    ; Bind the new hotkey
    currentShieldHotkey := newKey
    Hotkey "*" currentShieldHotkey, quickshield, "On"

    HotIf()
}

quickshield(*)
{
    global cfg

    if !cfg["checkbox_quickshield"]
        return

    Send "{" cfg["dropdown_shield"] " down}"
    Sleep 50
    Send "{" cfg["dropdown_shield"] " up}"
    Sleep 50

}



#HotIf