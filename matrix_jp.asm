; Matrix Effect in Assembly (x86_64) 
; Support green, red, blue, white, purple, yellow, pink

section .data
    hide_cursor db 0x1B, "[?25l", 0
    def_color   db 0x1B, "[32m", 0
    red         db 0x1B, "[31m", 0
    blue        db 0x1B, "[34m", 0
    white       db 0x1B, "[37m", 0
    purple      db 0x1B, "[35m", 0
    yellow      db 0x1B, "[33m", 0
    pink        db 0x1B, "[38;5;205m", 0

    str_red    db "red", 0
    str_blue   db "blue", 0
    str_white  db "white", 0
    str_purple db "purple", 0
    str_yellow db "yellow", 0
    str_pink   db "pink", 0

    rand_state dq 0x123456789ABCDEF1

    SYS_IOCTL  equ 16
    TIOCGWINSZ equ 0x5413

section .bss
    winsize    resw 4       
    columns    resb 512     
    buffer     resb 8192    
    selected_c resq 1

section .text
    global _start

_start:
    pop rax
    cmp rax, 2
    jl .set_default

    pop rax
    pop rsi

    mov rdi, str_red
    call str_compare
    jz .set_red
    mov rdi, str_blue
    call str_compare
    jz .set_blue
    mov rdi, str_white
    call str_compare
    jz .set_white
    mov rdi, str_purple
    call str_compare
    jz .set_purple
    mov rdi, str_yellow
    call str_compare
    jz .set_yellow
    mov rdi, str_pink
    call str_compare
    jz .set_pink

.set_default: mov qword [selected_c], def_color
    jmp .start_effect
.set_red: mov qword [selected_c], red
    jmp .start_effect
.set_blue: mov qword [selected_c], blue
    jmp .start_effect
.set_white: mov qword [selected_c], white
    jmp .start_effect
.set_purple: mov qword [selected_c], purple
    jmp .start_effect
.set_yellow: mov qword [selected_c], yellow
    jmp .start_effect
.set_pink: mov qword [selected_c], pink
    jmp .start_effect

.start_effect:
    mov rdi, hide_cursor
    call print_string

    mov rdi, [selected_c]
    call print_string

    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [rand_state], rax

.main_loop:
    mov rax, SYS_IOCTL
    mov rdi, 1
    mov rsi, TIOCGWINSZ
    mov rdx, winsize
    syscall

    movzx r12, word [winsize + 2]
    test r12, r12
    jnz .check_max
    mov r12, 80
.check_max:
    cmp r12, 512
    jbe .size_ok
    mov r12, 512
.size_ok:

    xor rcx, rcx

    ; --- INYECCIÓN ANSI PARA CASCADA DESCENDENTE ---
    ; \e[H  -> Mueve el cursor a la fila 1, columna 1
    ; \e[L  -> Inserta una línea nueva, empujando todo hacia abajo
    mov byte [buffer + rcx], 0x1B
    mov byte [buffer + rcx + 1], '['
    mov byte [buffer + rcx + 2], 'H'
    mov byte [buffer + rcx + 3], 0x1B
    mov byte [buffer + rcx + 4], '['
    mov byte [buffer + rcx + 5], 'L'
    add rcx, 6
    ; -----------------------------------------------

    xor r9, r9

.col_loop:
    mov rax, [rand_state]
    mov rdx, rax
    shl rdx, 13
    xor rax, rdx
    mov rdx, rax
    shr rdx, 7
    xor rax, rdx
    mov rdx, rax
    shl rdx, 17
    xor rax, rdx
    mov [rand_state], rax

    mov bl, byte [columns + r9]
    test bl, bl
    jnz .active_col

.inactive_col:
    cmp al, 2
    ja .print_space
    mov bl, ah
    and bl, 0x0F
    add bl, 15
    mov byte [columns + r9], bl
    jmp .print_char

.active_col:
    dec bl
    mov byte [columns + r9], bl

.print_char:
    test al, 0x01
    jz .add_number

.add_katakana:
    mov byte [buffer + rcx], 0xEF
    mov byte [buffer + rcx + 1], 0xBD
    mov rdx, rax
    shr rdx, 16
    and dl, 0x1F
    add dl, 0xA1
    cmp dl, 0xC0
    jne .store_k
    dec dl
.store_k:
    mov byte [buffer + rcx + 2], dl
    add rcx, 3
    jmp .next_col

.add_number:
    mov rdx, rax
    shr rdx, 24
    and dl, 0x09
    add dl, 0x30
    mov byte [buffer + rcx], dl
    inc rcx
    jmp .next_col

.print_space:
    mov byte [buffer + rcx], 0x20
    inc rcx

.next_col:
    inc r9
    cmp r9, r12
    jb .col_loop

.flush:
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, rcx
    syscall

    mov r8, 0x01FFFFFF
.delay:
    dec r8
    jnz .delay
    
    jmp .main_loop

str_compare:
    push rsi
    push rdi
.loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc rsi
    inc rdi
    jmp .loop
.not_equal:
    pop rdi
    pop rsi
    mov al, 1
    test al, al
    ret
.equal:
    pop rdi
    pop rsi
    xor rax, rax
    ret

print_string:
    xor rdx, rdx
.len:
    cmp byte [rdi + rdx], 0
    je .out
    inc rdx
    jmp .len
.out:
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    syscall
    ret
