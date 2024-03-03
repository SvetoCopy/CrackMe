;----------------------------------------------------------------------------------
; Memcpy – copying disjoint arrays.
; Way of passing arguments: PASCAL
; 
; Entry: STACK[0] - destination
;		 STACK[1] - source
;		 STACK[2] - count
; Destr: di, si 
;
;----------------------------------------------------------------------------------
MemCpy	proc
	
			push bp			; saving bp
			push cx			; saving cx
			push ax			; saving ax

			mov bp, sp		

			mov di, [bp + 8]  ; getting destination
			mov si, [bp + 10] ; getting source
			mov cx, [bp + 12] ; getting count
			
			cld
			rep movsb		; while(cx--) es:[di++] = ds:[si++]);

			pop ax			; getting old ax
			pop cx			; getting old cx
			pop bp			; getting old bp

			ret 6			; exit from func and clear stack

			endp

;----------------------------------------------------------------------------------
; Memset – fills the memory with the specified characters.
; Way of passing arguments: PASCAL
; 
; Entry: STACK[0] - address
;		 STACK[1] - symbol
;		 STACK[2] - count
; Destr: di, si 
;
;----------------------------------------------------------------------------------
MemSet	proc

			push bp			; saving bp
			push cx			; saving cx
			push ax			; saving ax

			mov bp, sp		

			mov di, [bp + 8]  ; getting address
			mov ax, [bp + 10] ; al = symbol
			mov cx, [bp + 12] ; cx = count	

			cld
			rep stosw		; while(cx--) es:[di++] = ax);

			pop ax			; getting old ax
			pop cx			; getting old cx
			pop bp			; getting old bp

			ret 6			; exit from func and clear stack

			endp

;----------------------------------------------------------------------------------
; Memchr – searches for the first occurrence of the specified character in the str.
; Way of passing arguments: PASCAL
; 
; Entry: STACK[0] - str
;		 STACK[1] - symbol (only low byte)
; Ret:	 CX		  - index
; Destr: di, si
;
;----------------------------------------------------------------------------------
MemChr	proc

			push bp			; saving bp
			
			mov bp, sp		

			push ax			; saving ax

			mov di, [bp + 4]  ; getting first arg

			mov ax, [bp + 6]	; al = symbol

			xor cx, cx		; cx = -1
			dec cx			
			
			cld
			repne scasb		; while(cx-- && es:[di++] != al);

			neg cx			; cx = - cx - 2
			dec cx
			dec cx

			pop ax			; getting old ax
			pop bp			; getting old bp
			
			ret 4			; exit from func and clear stack

			endp

;-------------------------------------------------------------------------------
; The function calculates the length of a string that ends with $
; Way of passing arguments: PASCAL
; 
; Entry: STACK[0] - str
; Ret:	 CX		  - length
; Destr: di, si
;
;-------------------------------------------------------------------------------
StrLenAsm	proc

			push bp			; saving bp
			push ax			; saving ax

			mov bp, sp		

			mov di, [bp + 6]  ; getting first arg

			lea si, EndSym	; si = &EndSym
			lodsb			; al = ds:[si++]

			xor cx, cx		; cx = -1
			dec cx			

			cld
			repne scasb		; while(cx-- && es:[di++] != al);

			neg cx			; cx = - cx - 1
			dec cx

			pop ax			; getting old ax
			pop bp			; getting old bp
			
			ret 2			; exit from func and clear stack

			endp
