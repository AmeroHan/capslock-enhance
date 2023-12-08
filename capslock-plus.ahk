#Requires AutoHotkey v2.0
#SingleInstance Force

SetStoreCapsLockMode false

global bCapsLockDown := false
global bCapsLockDown_Physical := false
global ActiveActionCount := 0
global bActionTriggered := false

; showState() {
; 	global
; 	ToolTip('CapsLock: ' . (bCapsLockDown ? 'T' : 'F') . (bCapsLockDown_Physical ? '_' : '^')
; 		. '`nAction: ' . ActiveActionCount
; 		. '`nActionTriggered: ' . (bActionTriggered ? 'T' : 'F')
; 	)
; }

*$CapsLock::{
	global
	bCapsLockDown := bCapsLockDown_Physical := true
	; if ActiveActionCount > 0 {  ; 动作还在在执行
	; 	return
	; }
	ActiveActionCount := 0
	bActionTriggered := false
}

*$CapsLock Up::{
	global
	bCapsLockDown_Physical := false
	if ActiveActionCount > 0 {  ; 动作还在在执行
		return
	}
	bCapsLockDown := false
	if not bActionTriggered {
		SendInput '{Blind}{CapsLock}'
	}
}


/*
Params:
- OutModifier: str
- Blind: bool = true
*/
RedirectKey(InKey, OutKey, Params := {}) {
	DownHotkey := '*' InKey
	UpHotkey := DownHotkey ' Up'
	DownOut := '{' OutKey ' Down}'
	UpOut := '{' OutKey ' Up}'

	DownOutModif := ''
	UpOutModif := ''
	if HasProp(Params, 'OutModifier') {
		pOutModifier := Params.OutModifier
		if pOutModifier is String {
			static ModifierMap := Map('#', 'Win', '!', 'Alt', '^', 'Ctrl', '+', 'Shift')
			Modifiers := []
			for c in StrSplit(pOutModifier, '') {
				Modifiers.push(ModifierMap[c])
			}
		} else {
			Modifiers := pOutModifier
		}
		for Modifier in Modifiers {
			DownOutModif .= '{' Modifier ' Down}'
			UpOutModif := '{' Modifier ' Up}' UpOutModif
		}
	}

	Blind := HasProp(Params, 'Blind') ? Params.Blind : '{Blind}'
	DownOut := Blind . DownOut
	UpOut := Blind . UpOut . UpOutModif

	bActive := false

	DownFunc(*) {
		global bActionTriggered, ActiveActionCount
		if not bActive {
			bActive := true
			bActionTriggered := true
			ActiveActionCount++
			if DownOutModif {
				SendInput DownOutModif
			}
		}
		SendInput DownOut
	}

	UpFunc(*) {
		global ActiveActionCount, bCapsLockDown, bCapsLockDown_Physical
		bActive := False
		ActiveActionCount--
		SendInput UpOut
		if not bCapsLockDown_Physical and ActiveActionCount <= 0 {  ; 已经松开CapsLock
			bCapsLockDown := false
		}
	}

	global bCapsLockDown
	HotIf 'bCapsLockDown'
	Hotkey DownHotkey, DownFunc
	Hotkey UpHotkey, UpFunc
	HotIf
}

SendInstance(InputToSend) {
	global bActionTriggered := true
	SendInput InputToSend
}

#HotIf bCapsLockDown

RedirectKey 'e', 'Up'
RedirectKey 'd', 'Down'
RedirectKey 's', 'Left'
RedirectKey 'f', 'Right'
RedirectKey 't', 'PgUp'
RedirectKey 'b', 'PgDn'


; ### 按单词移动光标
Params := { OutModifier: '^', Blind: '{Blind!#+}' }
RedirectKey 'a', 'Left', Params
RedirectKey 'g', 'Right', Params


; ### 移动光标至行首行尾，页首页尾
p::SendInstance '{Home}'
!p::SendInstance '^{Home}'
`;::SendInstance '{End}'
!`;::SendInstance '^{End}'

; ## 选中
; ### 按字符选中
Params := { OutModifier: '+', Blind: '{Blind!#^}' }
RedirectKey 'i', 'Up', Params
RedirectKey 'k', 'Down', Params
RedirectKey 'j', 'Left', Params
RedirectKey 'l', 'Right', Params
RedirectKey 'y', 'PgUp', Params
RedirectKey 'n', 'PgDn', Params

; ### 按单词选中
Params := { OutModifier: '+^', Blind: '{Blind!#}' }
RedirectKey 'h', 'Left', Params
RedirectKey '.', 'Right', Params
; ### 选中当前单词/当前行
,::SendInstance '{Ctrl Down}{Left}+{Right}{Ctrl Up}'
!,::SendInstance '{Home}+{End}'
; ### 选中至行首行尾，页首页尾，当前行
u::SendInstance '+{Home}'
!u::SendInstance '+^{Home}'
o::SendInstance '+{End}'
!o::SendInstance '+^{End}'

; ## 回车
RedirectKey 'Space', 'Enter'

; ## 退格/删除
; ### 单个字符
RedirectKey 'w', 'Backspace'
RedirectKey 'r', 'Del'
; ### 删除至行首/行尾
[::SendInstance '+{Home}{Backspace}'
/::SendInstance '+{End}{Del}'
; ### 删除整行/整段
Backspace::SendInstance '{End}+{Home}{Backspace}'
!Backspace::SendInstance '^a{Backspace}'

#HotIf
