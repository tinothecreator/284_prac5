; ==========================
; Group member 01: Tafara_Hwata-22565991
; Group member 02: Luba_Tshikila-u22644106
; Group member 03: Tinotenda_Chirozvi-22668323
; ==========================

; extern malloc

; section .text
;    global readPPM

; readPPM:
; section .data
;    inputFilename db "image01.ppm", 0             ; Name of the input PPM file
;    rb_mode db "rb", 0                          ; Binary read mode
;    max_header_size equ 512                     ; Maximum header size to read
;    p6_format db "P6", 0                        ; Expected format
;    fail_msg db "Failed to read the image.", 10, 0
;    alloc_err db "Memory allocation failed.", 10, 0
;    validate_err db "Invalid metadata values.", 10, 0
;    format_string db "%d %d %d", 0              ; sscanf format string

; section .bss
;    header_buffer resb max_header_size          ; Buffer to hold the header
;    width resd 1                                ; Width of the image
;    height resd 1                               ; Height of the image
;    maxColorValue resd 1                        ; Maximum color value
;    head resq 1                                 ; Head of linked list
;    prev_row_start resq 1                       ; Start of previous row in the list
;    prev_node resq 1                            ; Last node in current row

; section .text
;    extern fopen, fread, fclose, printf, sscanf, malloc
;    global readPPM

; readPPM:
;    push rbp
;    mov rbp, rsp
;    sub rsp, 64                                 ; Allocate stack space

;    ; Open the file in binary read mode
;    mov rdi, inputFilename
;    mov rsi, rb_mode
;    call fopen
;    test rax, rax                               ; Check if fopen returned NULL
;    jz fopen_fail

;    ; Store file pointer in local variable
;    mov [rbp-8], rax

;    ; Read header data
;    mov rdi, header_buffer                      ; Buffer to read header into
;    mov rsi, 1                                  ; Size of each element to read
;    mov rdx, max_header_size                    ; Number of elements (bytes) to read
;    mov rcx, [rbp-8]                            ; File pointer
;    call fread
;    test rax, rax                               ; Check if fread succeeded
;    jz fread_fail

;    ; Parse header buffer
;    mov rdi, header_buffer                      ; Buffer to parse
;    call parse_header
;    test rax, rax                               ; Check if parsing succeeded
;    jz parse_fail

;    ; Validate width, height, and maxColorValue
;    mov eax, [width]
;    test eax, eax
;    jle validate_fail
;    mov eax, [height]
;    test eax, eax
;    jle validate_fail
;    mov eax, [maxColorValue]
;    test eax, eax
;    jle validate_fail

;    ; Initialize head pointer to NULL
;    xor rax, rax
;    mov [head], rax

;    ; Read pixel data and construct the linked list
;    mov rcx, [width]                            ; Width in RCX
;    mov rdx, [height]                           ; Height in RDX

;    mov rbx, 0                                  ; Row index
;    .row_loop:
;       xor rsi, rsi                             ; Column index
;       xor rdi, rdi                             ; Start of the current row (null initially)
      
;       .col_loop:
;          ; Allocate memory for new PixelNode (48 bytes)
;          mov rdi, 48                           ; Size of PixelNode
;          call malloc
;          test rax, rax
;          jz malloc_fail
;          mov [prev_node], rax                  ; Current node

;          ; Read RGB data and store in PixelNode
;          mov rdi, rax                          ; Current PixelNode address
;          call readRGB                          ; Read and store RGB values

;          ; Initialize CdfValue to 0
;          mov byte [rax + 3], 0                 ; CdfValue

;          ; Link pixels in the 2D structure
;          ; If first row, no "up" pointer, else link up
;          cmp rbx, 0
;          je .skip_up
;          mov rdi, [prev_row_start]             ; Get node above current
;          add rdi, rsi                          ; Move across columns if necessary
;          mov [rax + 8], rdi                    ; Link "up"
;          mov [rdi + 16], rax                   ; Link "down"
;          .skip_up:

;          ; Link left if not first column
;          cmp rsi, 0
;          je .skip_left
;          mov rdi, [prev_node]                  ; Previous node in the row
;          mov [rax + 24], rdi                   ; Link "left"
;          mov [rdi + 32], rax                   ; Link "right"
;          .skip_left:

;          ; Move to next column
;          inc rsi
;          cmp rsi, rcx                          ; Check if column end reached
;          jl .col_loop

;       ; Set start of this row for the next row's "up" linking
;       mov [prev_row_start], rdi

;       ; Move to the next row
;       inc rbx
;       cmp rbx, rdx                             ; Check if row end reached
;       jl .row_loop

;    ; Close the file and return the head pointer
;    mov rdi, [rbp-8]
;    call fclose
;    mov rax, [head]                             ; Return the head of linked list
;    leave
;    ret

; fopen_fail:
; fread_fail:
; ; parse_fail:
; validate_fail:
; malloc_fail:
;    mov rdi, fail_msg
;    call printf
;    xor rax, rax                                ; Return NULL
;    leave
;    ret

; ; -----------------------------------------------------------
; ; Helper Function: parse_header
; ; Parses the header buffer for "P6", width, height, and maxColorValue
; ; -----------------------------------------------------------
; parse_header:
;    push rbp
;    mov rbp, rsp

;    ; Verify header starts with "P6"
;    mov rdi, header_buffer                ; Start of buffer
;    mov rsi, p6_format                     ; Expected format "P6"
;    call check_format
;    test rax, rax
;    jz format_error                        ; Exit if format mismatch

;    ; Use sscanf to parse width, height, and maxColorValue from header
;    mov rdi, header_buffer                 ; Input buffer (header data)
;    lea rsi, [rel format_string]           ; Load format string location
;    lea rdx, [width]                       ; Store width in `width`
;    lea rcx, [height]                      ; Store height in `height`
;    lea r8, [maxColorValue]                ; Store maxColorValue in `maxColorValue`
;    call sscanf
;    test rax, rax                          ; Check if sscanf succeeded
;    jz parse_fail                          ; Fail if sscanf returns 0

;    mov rax, 1                             ; Return success
;    leave
;    ret

; format_error:
; parse_fail:
;    xor rax, rax                           ; Indicate failure
;    leave
;    ret

; ; -----------------------------------------------------------
; ; Helper Function: check_format
; ; Compares first few bytes of header buffer to "P6" format
; ; -----------------------------------------------------------
; check_format:
;    mov al, byte [rdi]                          ; First character in buffer
;    cmp al, 'P'
;    jne format_error

;    mov al, byte [rdi + 1]                      ; Second character in buffer
;    cmp al, '6'
;    jne format_error

;    mov rax, 1                                  ; Indicate format is correct
;    ret

; ; -----------------------------------------------------------
; ; Helper Function: readRGB
; ; Reads RGB values from file and stores them in the PixelNode
; ; -----------------------------------------------------------
; readRGB:
;    push rbp
;    mov rbp, rsp

;    ; Assume file pointer is in [rbp-8], read 3 bytes for RGB into PixelNode
;    mov rdi, [rbp-8]                            ; File pointer
;    mov rsi, 3                                  ; Read 3 bytes (RGB)
;    mov rdx, 1                                  ; Read 1 pixel's worth
;    call fread

;    ; Store Red, Green, Blue values in PixelNode at RDI
;    mov al, byte [header_buffer]
;    mov byte [rdi], al                          ; Store Red
;    mov al, byte [header_buffer + 1]
;    mov byte [rdi + 1], al                      ; Store Green
;    mov al, byte [header_buffer + 2]
;    mov byte [rdi + 2], al                      ; Store Blue

;    leave
;    ret


   
section .data
    LC0 db "rb", 0          ; Message to print before displaying the ciphertext
    LC1 db "%2s", 0  ; Prompt for user input
    LC2 db "P6", 0              ; 32-bit XOR constant
    LC3 db "%d %d %d", 0                      ; Format for reading 4-character input
    

extern malloc,fopen,__isoc99_fscanf,fclose,strcmp, fgetc,ungetc,fread,free

section .text
    global readPPM

readPPM:
        push    rbp
        mov     rbp, rsp
        push    rbx
        sub     rsp, 104
        mov     qword  [rbp-104], rdi
        mov     rax, qword  [rbp-104]
        lea     esi, [LC0]
        mov     rdi, rax
        call    fopen
        mov     qword  [rbp-48], rax
        cmp     qword  [rbp-48], 0
        jne     .L2
        mov     eax, 0
        jmp     .L25
.L2:
        lea     rdx, [rbp-75]
        mov     rax, qword  [rbp-48]
        lea     esi, [LC1]
        mov     rdi, rax
        mov     eax, 0
        call    __isoc99_fscanf
        cmp     eax, 1
        jne     .L4
        lea     rax, [rbp-75]
        lea     esi, [LC2]
        mov     rdi, rax
        call    strcmp
        test    eax, eax
        je      .L6
.L4:
        mov     rax, qword  [rbp-48]
        mov     rdi, rax
        call    fclose
        mov     eax, 0
        jmp     .L25
.L8:
        nop
.L7:
        mov     rax, qword  [rbp-48]
        mov     rdi, rax
        call    fgetc
        cmp     eax, 10
        jne     .L7
.L6:
        mov     rax, qword  [rbp-48]
        mov     rdi, rax
        call    fgetc
        mov     dword  [rbp-52], eax
        cmp     dword  [rbp-52], 35
        je      .L8
        mov     rdx, qword  [rbp-48]
        mov     eax, dword  [rbp-52]
        mov     rsi, rdx
        mov     edi, eax
        call    ungetc
        lea     rsi, [rbp-88]
        lea     rcx, [rbp-84]
        lea     rdx, [rbp-80]
        mov     rax, qword  [rbp-48]
        mov     r8, rsi
        lea     esi, [LC3]
        mov     rdi, rax
        mov     eax, 0
        call    __isoc99_fscanf
        cmp     eax, 3
        jne     .L9
        mov     eax, dword  [rbp-88]
        cmp     eax, 255
        je      .L10
.L9:
        mov     rax, qword  [rbp-48]
        mov     rdi, rax
        call    fclose
        mov     eax, 0
        jmp     .L25
.L10:
        mov     rax, qword  [rbp-48]
        mov     rdi, rax
        call    fgetc
        mov     qword  [rbp-24], 0
        mov     eax, dword  [rbp-84]
        cdqe
        sal     rax, 3
        mov     rdi, rax
        call    malloc
        mov     qword  [rbp-64], rax
        mov     dword  [rbp-28], 0
        jmp     .L11
.L12:
        mov     eax, dword  [rbp-80]
        cdqe
        sal     rax, 3
        mov     edx, dword  [rbp-28]
        mov   rdx, rdx
        lea     rcx, [0+rdx*8]
        mov     rdx, qword  [rbp-64]
        lea     rbx, [rcx+rdx]
        mov     rdi, rax
        call    malloc
        mov     qword  [rbx], rax
        add     dword  [rbp-28], 1
.L11:
        mov     eax, dword  [rbp-84]
        cmp     dword  [rbp-28], eax
        jl      .L12
        mov     dword  [rbp-32], 0
        jmp     .L13
.L22:
        mov     dword  [rbp-36], 0
        jmp     .L14
.L21:
        mov     edi, 40
        call    malloc
        mov     qword  [rbp-72], rax
        cmp     qword  [rbp-72], 0
        jne     .L15
        mov     rax, qword  [rbp-48]
        mov     rdi, rax
        call    fclose
        mov     eax, 0
        jmp     .L25
.L15:
        mov     rax, qword  [rbp-72]
        mov     rdx, qword  [rbp-48]
        mov     rcx, rdx
        mov     edx, 1
        mov     esi, 1
        mov     rdi, rax
        call    fread
        mov     rax, qword  [rbp-72]
        lea     rdi, [rax+1]
        mov     rax, qword  [rbp-48]
        mov     rcx, rax
        mov     edx, 1
        mov     esi, 1
        call    fread
        mov     rax, qword  [rbp-72]
        lea     rdi, [rax+2]
        mov     rax, qword  [rbp-48]
        mov     rcx, rax
        mov     edx, 1
        mov     esi, 1
        call    fread
        mov     rax, qword  [rbp-72]
        mov     BYTE  [rax+3], 0
        mov     eax, dword  [rbp-32]
        cdqe
        lea     rdx, [0+rax*8]
        mov     rax, qword  [rbp-64]
        add     rax, rdx
        mov     rax, qword  [rax]
        mov     edx, dword  [rbp-36]
        mov  rdx, rdx
        sal     rdx, 3
        add     rdx, rax
        mov     rax, qword  [rbp-72]
        mov     qword  [rdx], rax
        cmp     dword  [rbp-36], 0
        jle     .L16
        mov     eax, dword  [rbp-32]
        cdqe
        lea     rdx, [0+rax*8]
        mov     rax, qword  [rbp-64]
        add     rax, rdx
        mov     rax, qword  [rax]
        mov     edx, dword  [rbp-36]
        mov   rdx, rdx
        sal     rdx, 3
        sub     rdx, 8
        add     rax, rdx
        mov     rdx, qword  [rax]
        mov     rax, qword  [rbp-72]
        mov     qword  [rax+24], rdx
        mov     eax, dword  [rbp-32]
        cdqe
        lea     rdx, [0+rax*8]
        mov     rax, qword  [rbp-64]
        add     rax, rdx
        mov     rax, qword  [rax]
        mov     edx, dword  [rbp-36]
        mov   rdx, rdx
        sal     rdx, 3
        sub     rdx, 8
        add     rax, rdx
        mov     rax, qword  [rax]
        mov     rdx, qword  [rbp-72]
        mov     qword  [rax+32], rdx
        jmp     .L17
.L16:
        mov     rax, qword  [rbp-72]
        mov     qword  [rax+24], 0
.L17:
        mov     rax, qword  [rbp-72]
        mov     qword  [rax+32], 0
        cmp     dword  [rbp-32], 0
        jle     .L18
        mov     eax, dword  [rbp-32]
        cdqe
        sal     rax, 3
        lea     rdx, [rax-8]
        mov     rax, qword  [rbp-64]
        add     rax, rdx
        mov     rax, qword  [rax]
        mov     edx, dword  [rbp-36]
        mov   rdx, rdx
        sal     rdx, 3
        add     rax, rdx
        mov     rdx, qword  [rax]
        mov     rax, qword  [rbp-72]
        mov     qword  [rax+8], rdx
        mov     eax, dword  [rbp-32]
        cdqe
        sal     rax, 3
        lea     rdx, [rax-8]
        mov     rax, qword  [rbp-64]
        add     rax, rdx
        mov     rax, qword  [rax]
        mov     edx, dword  [rbp-36]
        mov   rdx, rdx
        sal     rdx, 3
        add     rax, rdx
        mov     rax, qword  [rax]
        mov     rdx, qword  [rbp-72]
        mov     qword  [rax+16], rdx
        jmp     .L19
.L18:
        mov     rax, qword  [rbp-72]
        mov     qword  [rax+8], 0
.L19:
        mov     rax, qword  [rbp-72]
        mov     qword  [rax+16], 0
        cmp     dword  [rbp-32], 0
        jne     .L20
        cmp     dword  [rbp-36], 0
        jne     .L20
        mov     rax, qword  [rbp-72]
        mov     qword  [rbp-24], rax
.L20:
        add     dword  [rbp-36], 1
.L14:
        mov     eax, dword  [rbp-80]
        cmp     dword  [rbp-36], eax
        jl      .L21
        add     dword  [rbp-32], 1
.L13:
        mov     eax, dword  [rbp-84]
        cmp     dword  [rbp-32], eax
        jl      .L22
        mov     dword  [rbp-40], 0
        jmp     .L23
.L24:
        mov     eax, dword  [rbp-40]
        cdqe
        lea     rdx, [0+rax*8]
        mov     rax, qword  [rbp-64]
        add     rax, rdx
        mov     rax, qword  [rax]
        mov     rdi, rax
        call    free
        add     dword  [rbp-40], 1
.L23:
        mov     eax, dword  [rbp-84]
        cmp     dword  [rbp-40], eax
        jl      .L24
        mov     rax, qword  [rbp-64]
        mov     rdi, rax
        call    free
        mov     rax, qword  [rbp-48]
        mov     rdi, rax
        call    fclose
        mov     rax, qword  [rbp-24]
.L25:
        mov     rbx, qword  [rbp-8]
        leave
        ret

    