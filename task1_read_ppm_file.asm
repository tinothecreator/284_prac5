; ==========================
; Group member 01: Name_Surname_student-nr
; Group member 02: Name_Surname_student-nr
; Group member 03: Name_Surname_student-nr
; Group member 04: Name_Surname_student-nr
; Group member 05: Name_Surname_student-nr
; ==========================

; extern malloc

; section .text
;    global readPPM

; readPPM:
%define PixelNode_Red       0
%define PixelNode_Green     1
%define PixelNode_Blue      2
%define PixelNode_CdfValue  3
%define PixelNode_up        8
%define PixelNode_down      16
%define PixelNode_left      24
%define PixelNode_right     32
%define PixelNode_Size      40

section .data
   inputFilename db "image01.ppm", 0
   outputFilename db "output.ppm", 0
   rb_mode db "rb", 0
   max_header_size equ 512
   newline db 10, 0
   fail_msg db "Failed to read the image.", 10, 0

section .bss
   head resq 1
   width resd 1
   height resd 1
   maxColorValue resd 1
   header_buffer resb max_header_size

section .text
   global readPPM            ; Expose only readPPM function
   extern fopen, fread, fclose, malloc, printf

readPPM:
   ; Input: const char* filename (in rdi)
   ; Output: Returns pointer to head of 2D linked list in rax
   push rbp
   mov rbp, rsp
   sub rsp, 64                ; Allocate stack space for local variables

   ; Open the file in binary read mode
   mov rdi, inputFilename
   mov rsi, rb_mode           ; Load mode string "rb" from data section
   call fopen
   test rax, rax              ; Check if fopen returned NULL
   jz fopen_fail              ; Jump to error handling if fopen fails

   mov [rbp-8], rax           ; Store file pointer in local variable

   ; Read header data
   mov rdi, header_buffer
   mov rsi, 1 
   mov rdx, max_header_size             ; Only read one element of max_header_size
   mov rcx, [rbp-8]           ; Load file pointer into rdi for fread
   call fread
   test rax, rax              ; Check if fread succeeded
   jz fread_fail              ; Jump to error handling if fread fails

   ; Parse header buffer and set width, height, maxColorValue
   ; (Implementation here, e.g., loop through header_buffer for format, width, height, max color value)

   ; Allocate memory for the linked list
   mov rax, [width]
   imul rax, [height]
   imul rax, PixelNode_Size   ; Calculate total memory needed
   mov rdi, rax               ; Pass to malloc
   call malloc
   test rax, rax              ; Check if malloc succeeded
   jz malloc_fail             ; Jump to error handling if malloc fails

   ; Initialize 2D linked list of PixelNodes (pointer linking not shown)
   mov rdi, rax               ; Head of the linked list in rax

   ; Close the file and return head pointer
   mov rdi, [rbp-8]           ; Retrieve stored file pointer
   call fclose
   mov rax, rdi               ; Return head of linked list
   leave
   ret

fopen_fail:
   ; Handle fopen failure
   mov rdi, fail_msg          ; Load error message
   call printf                ; Print failure message
   xor rax, rax               ; Return NULL
   leave
   ret

fread_fail:
   ; Handle fread failure
   mov rdi, fail_msg          ; Load error message
   call printf                ; Print failure message
   mov rdi, [rbp-8]           ; Retrieve file pointer
   call fclose                ; Close the file
   xor rax, rax               ; Return NULL
   leave
   ret

malloc_fail:
   ; Handle malloc failure
   mov rdi, fail_msg          ; Load error message
   call printf                ; Print failure message
   mov rdi, [rbp-8]           ; Retrieve file pointer
   call fclose                ; Close the file
   xor rax, rax               ; Return NULL
   leave
   ret

main:
   ; Setup the filenames
   mov rdi, inputFilename
   call readPPM
   test rax, rax
   jz main_fail               ; If NULL, exit with error

   ; Head is stored in rax
   ; (Additional linked list processing here if needed)
   jmp main_end

main_fail:
   ; Error message
   mov rdi, fail_msg
   call printf
   mov eax, 1                 ; Return 1 for failure
   ret

main_end:
   xor eax, eax               ; Return 0 for success
   ret

    