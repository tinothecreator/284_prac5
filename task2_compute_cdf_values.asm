; ==========================
; Group member 01: Tafara_Hwata-22565991
; Group member 02: Luba_Tshikila-u22644106
; Group member 03: Tinotenda_Chirozvi-22668323
; ==========================

section .data
    blue_factor  dd 0.114
    green_factor dd 0.587
    max_value    dd 255.0
    zero_value   dd 0.0
    red_factor   dd 0.299    
    
section .bss
    cumulative   resd 256    ; Cumulative histogram array
    histogram    resd 256    ; Histogram array
    
section .text
    global computeCDFValues

computeCDFValues:
    push rbp
    mov rbp, rsp
    ; Save registers
    push rbx                
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi            ; Store head pointer
    xor r13, r13            ; Initialize totalPixels to 0
    mov rdi, histogram
    mov rcx, 256
    xor eax, eax
    rep stosd               ; Clear histogram array
    mov rdi, r12            ; Restore head pointer

; Build the histogram
build_histogram:
    test rdi, rdi           ; Check if head is null
    jz calculate_cdf        ; If null, jump to calculate_cdf
    
    mov rbx, rdi            ; Current pixel = current row
    
process_pixel_first_pass:
    cmp rbx, 0                ; Check if current pixel is null
    je next_row_first_pass
    
    ; Compute grayscale value
    pxor xmm0, xmm0

    mov al, byte [rbx]        ; Load red component
    movzx eax, al
    cvtsi2ss xmm1, eax
    mulss xmm1, [red_factor]
    addss xmm0, xmm1
    
    mov al, byte [rbx + 1]    ; Load green component
    movzx eax, al
    cvtsi2ss xmm1, eax
    mulss xmm1, [green_factor]
    addss xmm0, xmm1
    
    mov al, byte [rbx + 2]    ; Load blue component
    movzx eax, al
    cvtsi2ss xmm1, eax
    mulss xmm1, [blue_factor]
    addss xmm0, xmm1
    
    cvttss2si eax, xmm0       ; Convert to integer

    mov byte [rbx + 3], al    ; Store grayscale value in CdfValue
    add dword [histogram + rax*4], 1 ; Update histogram
    add r13, 1                ; Increment totalPixels
    mov rbx, [rbx + 32]       ; Move to next pixel using right pointer
    jmp process_pixel_first_pass
    
next_row_first_pass:
    mov rdi, [rdi + 16]         ; Move to next row using down pointer
    jmp build_histogram
    
calculate_cdf:
    xor rcx, rcx                ; i = 0
    xor rdx, rdx                ; cdf = 0
    mov r14d, -1                ; cdfMin = MAX_INT

cdf_loop:
    mov eax, [histogram + rcx*4]
    add edx, eax                ; cdf += histogram[i]
    mov [cumulative + rcx*4], edx

    test eax, eax               ; Check if histogram[i] > 0
    jz skip_min_update
    cmp edx, r14d
    jae skip_min_update
    mov r14d, edx               ; Update cdfMin
    
skip_min_update:
    inc rcx
    cmp rcx, 256
    jl cdf_loop
    mov rdi, r12                ; Restore head pointer
    
; Normalize CDF and update pixels
normalize_cdf:
    test rdi, rdi
    jz cleanup
    mov rbx, rdi                ; Current pixel = current row
    
process_pixel_second_pass:
    test rbx, rbx
    jz next_row_second_pass
    movzx ecx, byte [rbx + 3]   ; Load original grayscale value
    mov eax, [cumulative + rcx*4] ; Calculate normalized value
    sub eax, r14d               ; Numerator: cdf[i] - cdfMin
    
    cvtsi2ss xmm0, eax          ; Convert to float
    mov eax, r13d
    sub eax, r14d               ; Denominator: totalPixels - cdfMin
    cvtsi2ss xmm1, eax
    
    divss xmm0, xmm1            ; Perform division
    mulss xmm0, [max_value]     ; Multiply by 255

    maxss xmm0, [zero_value]    ; Clamp to [0, 255]
    minss xmm0, [max_value]
    
    cvttss2si eax, xmm0         ; Convert back to integer
    mov byte [rbx + 3], al
    mov rbx, [rbx + 32]         ; Move to next pixel
    jmp process_pixel_second_pass
    
next_row_second_pass:
    mov rdi, [rdi + 16]         ; Move to next row
    jmp normalize_cdf
    
cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret