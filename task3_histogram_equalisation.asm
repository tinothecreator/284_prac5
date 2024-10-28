; ==========================
; Group member 01: Tafara_Hwata-22565991
; Group member 02: Luba_Tshikila-u22644106
; Group member 03: Tinotenda_Chirozvi-22668323
; ==========================

section .data
    half_value  dd 0.5
    max_value   dd 255.0
    zero_value  dd 0.0

section .text
    global applyHistogramEqualisation

applyHistogramEqualisation:
    push rbp
    mov rbp, rsp
    ; Save registers
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    mov r12, rdi            ; Store head pointer

; Traverse the 2D Linked List
traverse_list:
    test r12, r12           ; Check if head is null
    jz cleanup              ; If null, jump to cleanup
    
    mov rbx, r12            ; Current pixel = current row
    
process_pixel:
    test rbx, rbx           ; Check if current pixel is null
    jz next_row
    
    ; Retrieve the normalized CdfValue
    movzx eax, byte [rbx + 3]
    cvtsi2ss xmm0, eax      ; Convert to float
    addss xmm0, [half_value] ; Add 0.5 for rounding
    cvttss2si eax, xmm0     ; Convert back to integer
    
    ; Clamp newPixelValue between 0 and 255
    maxss xmm0, [zero_value]
    minss xmm0, [max_value]
    cvttss2si eax, xmm0
    
    ; Set the pixel’s RGB values to newPixelValue
    mov byte [rbx], al
    mov byte [rbx + 1], al
    mov byte [rbx + 2], al
    
    mov rbx, [rbx + 32]     ; Move to next pixel using right pointer
    jmp process_pixel
    
next_row:
    mov r12, [r12 + 16]     ; Move to next row using down pointer
    jmp traverse_list
    
cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret