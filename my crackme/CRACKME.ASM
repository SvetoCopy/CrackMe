.286
.model tiny
.code
org 100h

FnMaxHeight		equ 24D
FnMaxWidth		equ 80d

FnHeight 		equ 7d
FnWidth			equ 30d
FnLineSize		equ 160d
FnLeftCornerX		equ 27d
FnLeftCornerY		equ 8d

FnStarSym		equ 2ah
FnStandartSet1_code	equ 31h
FnStandartSet2_code	equ 32h
FnStandartSet3_code 	equ 33h

FnSetSize		equ 9d

FnCMDArgsAddr		equ 80h
FnColor			equ 20h

FnInputBoxY             equ 12d
FnInputBoxX             equ 37d
FnInputBoxColor         equ 7h

InpSymColor             equ 0fh
AllowedColor            equ 20h
DeniedColor             equ 00C0h

FnAccessInfoY           equ 11d
FnAccessInfoX           equ 35d

LOCALS @@
Start:
                push 0b800h
                pop es

                lea bx, StandartSet1
                push bx

                lea bx, EndSym
                push bx
                mov ch, FnHeight
                mov dx, FnWidth
                mov ah, FnColor
                mov bx, FnLeftCornerX * 2 + FnLeftCornerY * FnLineSize
                call WriteFrame

                mov bx, (FnLeftCornerX + FnLeftCornerX / 2 - 2) * 2 + FnLeftCornerY * FnLineSize
                lea cx, Header_name
                mov ah, FnColor
                call WriteStrVarToFrame

                mov bx, FnInputBoxX * 2 + FnInputBoxY * FnLineSize
                lea cx, InpPass
                mov ah, FnInputBoxColor
                call WriteStrVarToFrame

                mov bx, FnInputBoxX * 2 + FnInputBoxY * FnLineSize
                call FrameInput

                mov ch, FnHeight
                mov dx, FnWidth
                mov bx, FnLeftCornerX * 2 + FnLeftCornerY * FnLineSize
                lea si, InpPass
                call CheckPassword

		mov ax, 4c00h
		int 21h

InpPass         db 10 DUP(' '), '$'
RealPassHash    db 00FEh
EndSym		db '$'
InpSym          db '*'
StandartSet1	db '/-\| |\-/'
Header_name	db 'PENTAGON$'
Allow_hname     db 'ACCESS ALLOWED$'
Deny_hname      db 'ACCESS DENIED!$'

;-------------------------------------------------------------------------------
; Check Password
; Entry:
;        CH - height infobox
;	 DX - width infobox
; 	 BX - left position infobox
;        SI - pwd address ( ended with $ )
;
; Return:
;        Al - status:
;                    0h - false
;                    1h - true
; Assumes:
;	 ES = 0b800h
; Destr: cx
;-------------------------------------------------------------------------------
CheckPassword	proc

                call HashStr

                cmp al, RealPassHash
                je @@is_true

                lea ax, StandartSet1            ; WriteFrame: access DENIED
                push ax

                lea ax, EndSym
                push ax

                mov ah, DeniedColor
                call WriteFrame

                mov bx, FnAccessInfoX * 2 + FnAccessInfoY * FnLineSize
                lea cx, Deny_hname
                mov ah, DeniedColor
                call WriteStrVarToFrame

                ret

@@is_true:
                lea ax, StandartSet1            ; WriteFrame: access ALLOWED
                push ax

                lea ax, EndSym
                push ax

                mov ah, AllowedColor
                call WriteFrame

                mov bx, FnAccessInfoX * 2 + FnAccessInfoY * FnLineSize
                lea cx, Allow_hname
                mov ah, AllowedColor
                call WriteStrVarToFrame

                ret
		endp

;-------------------------------------------------------------------------------
; Frame Input
; Entry:
; 	 BX - input box position
; Assumes:
;	 ES = 0b800h
; Destr: AX
;-------------------------------------------------------------------------------
FrameInput	proc

                lea si, InpPass
@@while_cond:
                mov ah, 08h
                int 21h

                cmp al, 0dh             ; check Enter
                jne @@while_body

                ret

@@while_body:
                cmp al, 08h             ; check delete
                je @@clear_sym

                mov [si], al
                inc si

                mov al, InpSym
                mov ah, InpSymColor
                call WriteSym
                add bx, 2

                jmp @@while_cond

@@clear_sym:
                dec si
                mov al, ' '
                mov [si], al

                sub bx, 2
                mov al, ' '
                mov ah, InpSymColor
                call WriteSym

                jmp @@while_cond

                endp

;-------------------------------------------------------------------------------
; Write str to frame
; Entry:
;	 AH - bkgd_color
;	 CX - str address ( ended with $ )
;	 BX - start pos
; Assumes:
;	 ES = 0b800h
; Destr: cx
;-------------------------------------------------------------------------------
WriteStrVarToFrame	proc

		push si ax bx

@@while_cond:
		mov si, cx
		lodsb
		cmp al, EndSym
		jne @@while_body

		pop bx ax si

		ret

@@while_body:
		mov es:[bx], ax

		inc cx
		add bx, 2
		jmp @@while_cond

		endp

;-------------------------------------------------------------------------------
; Calculate Left Corner Position
; Ret:
;        DX - width
;	 CH - height
; Ret:
;	 BX - left pos
;
; Destr: BX
;
;------------------------------------------------------------------------------
CalculateLeftPos	proc

                mov bx, FnLineSize ; bx= (FnLineSize - 2 * width) // 2

                sub bx, dx
                sub bx, dx

                shr bx, 1

                shr bx, 1			; bx = ( bx // 2 ) * 2
                shl bx, 1

                push dx
                push ax
                mov ah, 0
                mov al, FnMaxHeight	; al = (FnMaxHeight - height) // 2
                sub al, ch
                shr al, 1

                push cx

                mov cx, FnLineSize	; bx += al * FnLineSize
                mul cx

                add bx, ax

                pop cx
                pop ax
                pop dx

                ret
		endp

;-------------------------------------------------------------------------------
; Write frame to VMemory
; Entry:
;	 CH - height
;	 DX - width
; 	 BX - left position
;	 AH - color
;	 STACK[0] - str_address
;	 STACK[1] - set_adress
; Assumes:
;	 ES = 0b800h
; Destr: AX, CX, BX, DX
;-------------------------------------------------------------------------------
WriteFrame	proc

		push bp			; saving bp
		mov bp, sp

		push cx			; saving height
		push dx			; saving width
		push bx			; saving left pos

		mov cl, 1h		; print_first_line

		push dx			; saving dx
		push bx			; saving bx

		push [bp + 6]
		call WriteFrameLine

		pop bx			; getting old bx
		pop dx			; getting old dx

		add bx, FnLineSize	; bx = bx + Line_size
	    Sub ch, 1

@@while_cond:
		cmp ch, 1		; while ( height > 1 )
		jle @@end_while

		mov cl, 2h		; print_middle_line

		push dx			; saving dx
		push bx			; saving bx
		push [bp + 6]
		call WriteFrameLine
		pop bx			; getting old bx
		pop dx			; getting old dx

		sub ch, 1
		add bx, FnLineSize	; bx = bx + Line_size

		jmp @@while_cond

@@end_while:
		mov cl, 3h		; print_last_line
		push [bp + 6]
		Call WriteFrameLine
		pop bx			; getting old left pos
		pop dx			; getting old width
		pop cx
		pop bp			; getting old bp

		ret 4			; exit from func and clear stack
		endp

;-------------------------------------------------------------------------------
; Write a line of frame to VMemory
; Entry:
;	 AH - color
;	 CL - line_type:
;		  	1h - first line
;			2h - middle line
;			3h - last line
; 	 DX - width
;	 BX - left position
;	 STACK[0] - CurrentSet
; Assumes:
;	 ES = 0b800h
; Destr: AL, CL, BX, DX, SI
;
;-------------------------------------------------------------------------------

WriteFrameLine	proc

check_1:
		push bp			; saving bp
		mov bp, sp
		cmp cl, 1h
		jne check_2

		mov si, [bp + 4]			; passing argument right_border
		add si, 2
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument left_border
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument middle_sym
		add si, 1
		mov cl, [si]

		call WriteSymLine

		pop bp			; getting old bp

		ret 2

check_2:
		cmp cl, 2h
		jne check_3

		mov si, [bp + 4]			; passing argument right_border
		add si, 5
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument left_border
		add si, 3
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument middle_sym
		add si, 4
		mov cl, [si]

		call WriteSymLine

		pop bp			; getting old bp

		ret 2

check_3:

		mov si, [bp + 4]			; passing argument right_border
		add si, 8
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument left_border
		add si, 6
		mov al, [si]
		push ax

		mov si, [bp + 4]			; passing argument middle_sym
		add si, 7
		mov cl, [si]

		call WriteSymLine

		pop bp			; getting old bp

		ret 2			; exit from func and clear stack
		endp
;-------------------------------------------------------------------------------
; Writes a sequence of identical characters in a line with borders.
; Example: [|==============|]
;
; Entry: AH - background color
;	 CL 	  - middle symbol
;	 BX 	  - left position
;	 DX 	  - width
;	 STACK[0] - left_border   (left_border higher then
;	 STACK[1] - right_border   right_border in stack)
; Assumes:
;	 ES = 0b800h
; Destr: BX, DX, AL
;-------------------------------------------------------------------------------

WriteSymLine 	proc

		push bp			; saving bp
		mov bp, sp

		push dx			; saving dx [*]

		mov dx, [bp+4]		; getting left_border
		mov al, dl

		Call WriteSym

		pop dx			; getting old dx from [*]

		add bx, 2
		sub dx, 2 		; subbed left and right border

		push dx			; Memset(bx, ax, dx)
		mov al, cl
		push ax
		push bx
		Call MemSet

		add bx, dx		; left_pos += 2 * width
		add bx, dx

		mov dx, [bp+6]		; getting right_border
		mov al, dl

		call WriteSym

		pop bp			; getting old bp

		ret 4			; exit from func and clear stack
		endp

;-------------------------------------------------------------------------------
; Write str to VMemory
; Entry:
;	 SI - source address
;	 AH - color
;  	 BX - offset to VMemory
; Assumes:
;	 ES = 0b800h
; Destr: none
;
;------------------------------------------------------------------------------

WriteString	proc

while_6_cond:
		mov ch, [si]
		cmp ch, 24h
		jne while_6

		ret
while_6:
		mov al, ch
		Call WriteSym
		add bx, 2
		add si, 1
		jmp while_6_cond

		endp

;-------------------------------------------------------------------------------
; Write  a symbol to VMemory
; Entry: AH color,
;	 AL symbol
;  	 BX offset to VMemory
; Assumes:
;	 ES = 0b800h
; Destr: none
;
;------------------------------------------------------------------------------

WriteSym 	proc

		mov es:[bx], ax
		ret

		endp

;-------------------------------------------------------------------------------
; The function calculates the length of a box_text that ends with $
; Way of passing arguments: PASCAL
;
; Entry: STACK[0] - str
; Ret:	 CX		  - length
; Destr: si, al
;
;-------------------------------------------------------------------------------
StrLenBoxtext	proc

		push bp			; saving bp
		push ax			; saving ax

		mov bp, sp

		mov si, [bp + 6]  ; getting first arg


		xor cx, cx

@@while_cond:
		mov al, [si]
		cmp al, EndSym
		jne @@while_body

		pop ax			; getting old ax
		pop bp			; getting old bp

		ret 2			; exit from func and clear stack

@@while_body:

		add cx, 1
		add si, 1
		jmp @@while_cond

		endp

include strtonum.asm
include hash.asm
end 		Start
