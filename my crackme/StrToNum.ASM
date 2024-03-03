
;----------------------------------------------------------------------------------
; GetHexNum – getting hex number from ascii codes until it encounters a space
; Note: ONLY TWO BYTES
; Entry: SI - address
; Ret:	 BX		  - num
; Destr: di, si, cx, ax, dx
;
;----------------------------------------------------------------------------------
GetHexNum	proc

			mov bx, 0
			mov dh, 0
			mov dh, [si]	; bx = GetHexDigit([si]) * 16
			
			push dx
			call GetHexDigit

			add bx, ax
			shl bx, 4

			add si, 1

			mov dh, [si]	; bx += GetHexDigit([si + 1])

			push dx
			call GetHexDigit

			add bx, ax
			add si, 1

			ret
			endp

;----------------------------------------------------------------------------------
; GetDecNum – getting decimal number from ascii codes until it encounters a space
; 
; Entry: SI - address
; Ret:	 CX - num
; Destr: di, si 
;
;----------------------------------------------------------------------------------
GetDecNum	proc

			mov cx, 0

@@while_cond:
			mov dh, [si]

			cmp dh, 20h
			jne @@while_loop

			ret 

@@while_loop:
			
			push dx

			mov ax, 10d
			mul cx
			mov cx, ax
								
			call GetDecDigit	; GetDecDigit([si])

			add cx, ax			; cx += ax

			add si, 1
			jmp @@while_cond
			
			endp

;----------------------------------------------------------------------------------
; GetHexDigit – getting hex digit from ascii code
; 
; Entry: STACK[0] - code (only high byte)
; Ret:	 AX		  - digit
; Destr: di, si 
;
;----------------------------------------------------------------------------------
GetHexDigit	proc

			push bp			; saving bp

			mov bp, sp		

			mov ax, [bp + 4]

			sub ah, 30h
			cmp ah, 10d

			JL DecDigit

			sub ah, 11h

			cmp ah, 6
			jl  HexDigit

			sub ah, 20h

HexDigit:
			add ah, 10d
			mov al, ah
			mov ah, 0

			jmp @@end

DecDigit:
			push [bp + 4]
			call GetDecDigit

@@end:
			pop bp			; getting old ax

			ret 2			; exit from func and clear stack

			endp

;----------------------------------------------------------------------------------
; GetDecDigit – getting decimal digit from ascii code
; 
; Entry: STACK[0] - code (only high byte)
; Ret:	 AX		  - digit
; Destr: di, si 
;
;----------------------------------------------------------------------------------
GetDecDigit	proc

			push bp			; saving bp

			mov bp, sp		

			mov ax, [bp + 4]
			sub ah, 30h
			mov al, ah
			mov ah, 0

			pop bp			; getting old ax

			ret 2			; exit from func and clear stack

			endp

;----------------------------------------------------------------------------------
; SkipSpaces
; 
; Entry: SI - address
; Destr: DH
;
;----------------------------------------------------------------------------------
SkipSpaces	proc
			
@@while_cond:
			mov dh, [si]
			
			cmp dh, 20h
			je @@while_body

			ret
@@while_body:
			add si, 1
			jmp @@while_cond

			endp

DIG16		db '0123456789ABCDEF'

include string_f.asm


