

global write_pixel
global write_line
global clear_buffer

extern printf

section .data
  msg db "%ld", 10, 0


section .text

; flip sign on 64 bit
%macro ABS64 1
    imul %1, -1
%endmacro

%macro SWAP 2
  mov rax, %1
  mov %1, %2
  mov %2, rax
%endmacro

%macro PROLOGUE 0
  push rbp
  mov rbp, rsp
%endmacro

%macro EPILOGUE 0
  mov rsp, rbp
  pop rbp
  ret
%endmacro



; rdi -  is a pointer to the buffer
; rsi -  is the color to place (32 bit) 
; rdx -  the start x cordinate
; rcx -  the start y coordinate
; r8  -  the end x coordinate
; r9  -  the end y coordinate
; r10 -  the width of the buffer ; on the stack *
write_line:
  PROLOGUE

  ; rdi pointer to buffer
  ; rsi color
  ; rbx  start x
  ; rcx  start y
  ; r8 end x
  ; r9 end y
  ; r10  steep
  ; r11 dx
  ; r12 dy
  ; r13 downwards
  ; r14 derror
  ; r15 width of buffer

  sub rsp, 48
  mov [rsp], rbx
  mov [rsp + 8], r12 
  mov [rsp + 16], r13
  mov [rsp + 24], r14
  mov [rsp + 32], r15
  mov r15, [rbp + 16]

; check steep
  mov rbx, rdx
  mov rax, rdx
  sub rax, r8
  ABS64 rax

  mov rdx, rcx
  sub rdx, r9
  ABS64 rdx

  cmp rax, rdx
  jge not_steep
    SWAP rbx, r8
    SWAP rcx, r9

    mov r10, 1
    jmp steep_merge

not_steep:
    xor r10, r10
steep_merge:

  ; change smallest -> largest
  cmp rdx, r8 
  jle start_is_less 

  SWAP rbx, r8
  SWAP rcx, r9

start_is_less:

  ; calculate dy/dx
  ; dx
  mov r11, r8
  sub r11, rbx

  ; dy
  mov r12, r9
  sub r12, rcx
  add r12, r12
  cmp r12, 0
  jge upwards

downwards:
  ABS64 r12 
  mov r13, -1
  jmp up_merge

upwards:
  mov r13, 1

up_merge:
  xor r14, r14


  ; go from start x to end x
line_loop_head:
  cmp rbx, r8
  jge line_loop_end

  cmp r10, 0
  je was_steep
  mov rax, r15
  mul rcx
  jmp was_steep_merge
was_steep:
  mov rax, rcx
  imul rax, r15
was_steep_merge:
  add rax, rbx
  mov DWORD [rdi + rax * 4], esi

  ; derror += dy;
  add r14, r12

  cmp r14, r11
  jle increase_y_merge
  
  ; y = downwards ? y - 1 : y + 1;
  add rcx, r13
  
  lea rax, [r11 + r11]
  sub r14, rax
    
increase_y_merge:
  inc rbx
  jmp line_loop_head

line_loop_end:
  mov rbx, [rsp]
  mov r12, [rsp + 8]
  mov r13, [rsp + 16]
  mov r14, [rsp + 24]
  mov r15, [rsp + 32]
  EPILOGUE

;;;;;;;;;;;;;;;;;;;;;;;;;;

; rdi - is a pointer to the buffer
; rsi - is the color to place of an int
; rcx - the y coordinate
; r8  - the width of the buffer
; r9 - the x coordinate
write_pixel:
  PROLOGUE

  mov rax, r8
  mul rcx
  add rax, r9
  mov DWORD [rdi + rax * 4], esi

  EPILOGUE
; rdi - is a pointer to the buffer
; rsi - width of the buffer
; rdx - height of the buffer
; rcx - the color to clear with
clear_buffer:
  PROLOGUE

  mov rax, rsi
  mov rcx, rdx
  mul rcx
  mov rcx, rax
  mov rax, 0xFFFFFFFF
  rep stosd

  EPILOGUE
