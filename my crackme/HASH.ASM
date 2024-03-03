;-----------------------------------------------------------------------------------
; HASH FUNCTION for 10-character string ( ended with $ ) !!!HAVE A LOT OF СOLLISIONS
; Entry:
;       SI - str address ( ended with $ )
; Ret:
;       AX - Hash password
; Destr: AX, SI, DX
;-----------------------------------------------------------------------------------
HashStr	proc
                push dx
                mov ax, 0
@@while_cond:
                mov dh, EndSym
                cmp [si], dh
                jne @@while_body

                pop dx
                ret

@@while_body:
		add al, [si]
                inc si
                jmp @@while_cond

                endp
