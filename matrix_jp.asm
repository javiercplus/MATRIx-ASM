; -----------------------------------------------------------------------
; Matrix Effect in Assembly (x86_64) - Multi-color version
; Supports: green, red, blue, white, purple, yellow, pink
; -----------------------------------------------------------------------

section .data
    ; ANSI Color Codes
    def_color db 0x1B, "[32m", 0      ; Default Green
    red       db 0x1B, "[31m", 0
    blue      db 0x1B, "[34m", 0
    white     db 0x1B, "[37m", 0
    purple    db 0x1B, "[35m", 0
    yellow    db 0x1B, "[33m", 0
    pink      db 0x1B, "[38;5;205m", 0 ; Extended 256-color pink

    ; Color Names for Comparison
    str_red    db "red", 0
    str_blue   db "blue", 0
    str_white  db "white", 0
    str_purple db "purple", 0
    str_yellow db "yellow", 0
    str_pink   db "pink", 0

    rand_state dq 0x123456789ABCDEF1

section .bss
    buffer      resb 4096
    selected_c  resq 1               ; Pointer to the chosen color string

section .text
    global _start

_start:
    pop rax                          ; rax = argc
    cmp rax, 2
    jl .set_default
    
    pop rax                          ; Skip program name
    pop rsi                          ; rsi = first argument (color name)
    
    ; Compare argument with available colors
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

.set_default:
    mov qword [selected_c], def_color
    jmp .start_effect

.set_red:
    mov qword [selected_c], red
    jmp .start_effect
.set_blue:
    mov qword [selected_c], blue
    jmp .start_effect
.set_white:
    mov qword [selected_c], white
    jmp .start_effect
.set_purple:
    mov qword [selected_c], purple
    jmp .start_effect
.set_yellow:
    mov qword [selected_c], yellow
    jmp .start_effect
.set_pink:
    mov qword [selected_c], pink
    jmp .start_effect

.start_effect:
    mov rdi, [selected_c]
    call print_string

    rdtsc
    shl rdx, 32
    or rax, rdx
    mov [rand_state], rax

.main_loop:
    xor rcx, rcx

.fill_buffer:
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

    test al, 0x01
    jz .add_number

.add_katakana:
    cmp rcx, 4090
    jae .flush
    mov byte [buffer + rcx], 0xE3
    mov rdx, rax
    shr rdx, 8
    and dl, 1
    add dl, 0x82
    mov [buffer + rcx + 1], dl
    mov rdx, rax
    shr rdx, 16
    and dl, 0x1F
    add dl, 0xA1
    mov [buffer + rcx + 2], dl
    add rcx, 3
    jmp .check_full

.add_number:
    cmp rcx, 4095
    jae .flush
    mov rdx, rax
    shr rdx, 24
    and dl, 0x09
    add dl, 0x30
    mov [buffer + rcx], dl
    inc rcx

.check_full:
    cmp rcx, 3800
    jb .fill_buffer

.flush:
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, rcx
    syscall

    mov r8, 0x07FFFFFF
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
    test al, al  ; Clear ZF
    ret
.equal:
    pop rdi
    pop rsi
    xor rax, rax ; Set ZF
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