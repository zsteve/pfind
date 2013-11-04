.486
.model	flat, stdcall
option	casemap :none   ; case sensitive

; INCLUDES

include	windows.inc

uselib	MACRO	libname
	include		libname.inc
	includelib	libname.lib
ENDM

uselib	user32
uselib	kernel32

; PROTOTYPES

DlgProc		PROTO :DWORD,:DWORD,:DWORD,:DWORD
nPrime		PROTO :DWORD

; EQUATES

IDC_OK 			equ	1003
IDC_IDCANCEL 	equ	1004
IDC_INFO		equ 1005
; DATA 

.data?
hInstance		dd		?	;dd can be written as dword
pIn				dd		?	; variable for input of 1001 (prime number test input)
TSEC 			SECURITY_ATTRIBUTES <?>
hThread			dd		?

.data
mprime		db "Prime",0
mnotprime	db "Divisible by ", 64 dup(0)
msginfo		db "Info",0

infocap		db "About",0
infobox		db "pFind v1.00 : prime number finder",0ah
			db "code by zsteve in assembler",0ah
			db "http://zsteve.phatcode.net",0
strValue	db "Enter value here",0
workingtitle	db "Working..",0
donetitle		db "pFind",0
tCf			db		0	; flag for whether the 2nd thread has completed.
tRes		db		0 	; flag for the return value of nPrime
divbyv		dd		0
; CODE

.code
start:
	invoke	GetModuleHandle, NULL
	mov	hInstance, eax
	invoke	DialogBoxParam, hInstance, 101, 0, ADDR DlgProc, 0
	invoke	ExitProcess, eax

tFunc PROC
	; this is our second thread function
	push pIn	; push parameter : query number
	call nPrime	; call nPrime function
	mov divbyv, eax
	mov tRes, al	; save return value
	mov tCf, 1	; make tCf = 1
	Ret			; return
tFunc EndP

DlgProc	proc	hWin	:DWORD,
		uMsg	:DWORD,
		wParam	:DWORD,
		lParam	:DWORD

	.if	uMsg == WM_COMMAND
		.if	wParam == IDC_OK
			; we have a message from IDC_OK 
			; this means the button has been pressed
			; we will now process this.
			invoke GetDlgItemInt, hWin, 1001, 0, 0 ; we call GetDlgItemInt to retrieve the value of 1001 
													; as an INT, or a decimal number.
			mov pIn, eax 	; save the value.
			invoke CreateThread, offset TSEC, 128, addr tFunc, 0, 0, offset hThread ; Create a second thread 
																					; since prime finding can
																					; be a lengthy operation
			invoke SetTimer, hWin, 1, 10, 0
		.elseif wParam == IDC_INFO
			invoke MessageBox, hWin, offset infobox, offset infocap, MB_ICONINFORMATION
        .elseif	wParam == IDC_IDCANCEL
			invoke EndDialog,hWin,0
		.endif
	.elseif uMsg == WM_TIMER
		; here we will check whether the 2nd thread has completed
		.if tCf == 1
			; if tCf == 1 (which means the 2nd thread is done)
			mov tCf, 0
			invoke KillTimer, hWin, 1
			mov al, tRes
			cmp al, 1
			; 1006
			jne NotPrime
			invoke SetDlgItemText, hWin, 1006, offset mprime
			jmp skipnotprime
			NotPrime:
			invoke lstrlen, offset mnotprime
			add eax, offset mnotprime
			; here, eax == the offset to write to.
			invoke SetDlgItemInt, hWin, 1006, divbyv, 0
			skipnotprime:
			invoke SetWindowText, hWin, offset donetitle
		.else
			invoke SetWindowText, hWin, offset workingtitle
		.endif
	.elseif uMsg == WM_INITDIALOG
		mov tCf, 0	; make tCf 0
		invoke SetDlgItemText, hWin, 1001, offset strValue
	.elseif	uMsg == WM_CLOSE
		invoke	EndDialog,hWin,0
	.endif

	xor	eax,eax
	ret
DlgProc	endp

nPrime PROC pN:DWORD
LOCAL pHalf:DWORD
LOCAL divby:DWORD ; if the number is divisible
					; this is the number .
					
	; the DIV instruction takes EAX as dividend
	; ECX as divisor, and EDX as remainder storage.
	; the quotient is in EAX.
	mov eax, pN
	cmp eax, 2		; if EAX is 2, it's prime!
	je _prime
	mov ecx, 2 		; DIVISOR == 2
	xor edx, edx
	div ecx 		; effectively doing EAX = EAX / ECX -> EDX
	add eax, edx 	; add remainder to quotient
	mov pHalf, eax 	; save this as "half" of the query number.
					; now we will test if the LO BIT of pN is 0.
					; if it is, the number is EVEN, which means it's NOT PRIME.
	mov eax, pN
	shl eax, 31		; EAX is 32-bit.
	shr eax, 31
	cmp eax, 0 		; if EAX is now 0, it's divisible by 2.
	mov ecx, 2		; divisible by 2.
	je _notprime
					; otherwise we continue.
	mov ecx, 2		; start dividing by 2.
	_startloop:
	mov eax, pN
	xor edx, edx	; reason to XOR EDX, EDX is because if it's a clean
					; division, EDX will NOT be overwritten.
	div ecx			; divide EAX by ECX
	cmp edx, 0		; has it been divided cleanly?
	je _notprime	; if it has, it's not prime
	inc ecx			; otherwise, increment ECX
	cmp ecx, pHalf	; compare ECX with pHalf
	ja _prime		; if it's above pHalf (larger), then it's prime.
					; otherwise, keep going.
	jmp _startloop	; go to _startloop
	_prime:
	mov eax, 1
	ret
	_notprime:
	mov divby, ecx
	xor eax, eax
	mov eax, divby
	ret
nPrime EndP

end start
