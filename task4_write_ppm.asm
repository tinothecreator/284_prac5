; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Name_Surname_student-nr
; Group member 03: Name_Surname_student-nr
; Group member 04: Name_Surname_student-nr
; Group member 05: Name_Surname_student-nr
; ==========================
; Define offsets for PixelNode structure
%define PixelNode_right 0x00     ; Offset for the 'right' pointer
%define PixelNode_down  0x08     ; Offset for the 'down' pointer
%define PixelNode_Red   0x10     ; Offset for the 'Red' byte
%define PixelNode_Green 0x11     ; Offset for the 'Green' byte
%define PixelNode_Blue  0x12     ; Offset for the 'Blue' byte


section .data
    wb_mode db "wb", 0                   ; Write mode for binary files
    ppm_header db "P6", 10               ; PPM format identifier, newline
    header_space db " ", 0               ; Space separator for header
    header_newline db 10, 0              ; Newline for header

section .text
    global writePPM
    extern fopen, fwrite, fclose, sprintf, strlen

writePPM:
    ; Set up stack frame
    push rbp
    mov rbp, rsp
    sub rsp, 128                        ; Allocate space for locals if needed

    ; Open file in binary write mode
    mov rdi, [rbp+16]                   ; Load filename into rdi (first parameter)
    mov rsi, wb_mode                    ; Load "wb" mode into rsi (second parameter)
    call fopen
    test rax, rax                       ; Check if fopen succeeded
    jz fopen_fail                       ; Jump to error handling if fopen failed
    mov [file_ptr], rax                 ; Store file pointer in local variable

    ; Calculate width by traversing first row (using right pointers)
    mov rdi, [rbp+24]                   ; rdi = head pointer
    mov rcx, 0                          ; Width counter
calc_width:
    test rdi, rdi
    jz calc_height                      ; End if no more pixels in the row
    inc rcx                             ; Increment width counter
    mov rdi, [rdi + PixelNode_right]    ; Move to the next pixel on the right
    jmp calc_width
calc_height:
    mov [width], rcx                    ; Store calculated width

    ; Calculate height by traversing first column (using down pointers)
    mov rdi, [rbp+24]                   ; rdi = head pointer
    mov rcx, 0                          ; Height counter
calc_height_loop:
    test rdi, rdi
    jz write_header                     ; End if no more pixels in the column
    inc rcx                             ; Increment height counter
    mov rdi, [rdi + PixelNode_down]     ; Move to the next pixel downwards
    jmp calc_height_loop
write_header:
    mov [height], rcx                   ; Store calculated height

    ; Write PPM header to the file
    ; Format: "P6\nwidth height\n255\n"
    mov rdi, file_buffer                ; Prepare the buffer for header data
    mov rsi, ppm_header                 ; "P6" identifier
    call sprintf                        ; sprintf(file_buffer, "P6\n")
    mov rsi, [width]                    ; Load width
    mov rdx, header_space               ; Space separator
    call sprintf                        ; sprintf(file_buffer, "P6\nwidth ")
    mov rsi, [height]                   ; Load height
    call sprintf                        ; sprintf(file_buffer, "P6\nwidth height\n")
    mov rsi, max_color_value            ; 255 as max color
    mov rdx, header_newline             ; Newline separator
    call sprintf                        ; sprintf(file_buffer, "P6\nwidth height\n255\n")
    mov rsi, file_buffer                ; Pointer to header buffer
    mov rdi, [file_ptr]                 ; File pointer
    call fwrite                         ; fwrite(header)

    ; Write pixel data row-by-row
    mov rdi, [rbp+24]                   ; Set rdi to head pointer of the 2D list
write_rows:
    test rdi, rdi                       ; Check if head is null
    jz close_file                       ; End if null (all rows processed)
    mov rdx, rdi                        ; Save current row head in rdx
write_pixels:
    test rdx, rdx
    jz next_row                         ; End of row, move to next row
    mov al, byte [rdx + PixelNode_Red]  ; Load red component
    mov [color_buffer], al
    mov al, byte [rdx + PixelNode_Green]; Load green component
    mov [color_buffer+1], al
    mov al, byte [rdx + PixelNode_Blue] ; Load blue component
    mov [color_buffer+2], al

    ; Write RGB to file
    mov rdi, [file_ptr]                 ; File pointer
    mov rsi, color_buffer               ; Color buffer
    mov rdx, 3                          ; 3 bytes per pixel
    call fwrite                         ; fwrite(color_buffer, 3, 1, file)

    mov rdx, [rdx + PixelNode_right]    ; Move to next pixel in row
    jmp write_pixels

next_row:
    mov rdi, [rdi + PixelNode_down]     ; Move to the next row
    jmp write_rows                      ; Repeat for the next row

close_file:
    ; Close the file
    mov rdi, [file_ptr]                 ; Load file pointer
    call fclose                         ; fclose(file)

    ; Clean up and return
    mov rsp, rbp
    pop rbp
    ret

fopen_fail:
    ; Handle fopen failure
    ; (Could include printf or another error-handling function)
    mov rax, 0                          ; Return NULL
    mov rsp, rbp
    pop rbp
    ret

section .bss
    file_ptr resq 1                     ; File pointer storage
    width resq 1                        ; Image width
    height resq 1                       ; Image height
    file_buffer resb 64                 ; Buffer for the PPM header
    color_buffer resb 3                 ; Temporary buffer for RGB values
    max_color_value dd 255              ; Max color value (255 for PPM)

    