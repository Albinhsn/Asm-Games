

global write_pixel
global write_line
global write_unfilled_quad
global write_filled_quad
global write_filled_circle

global clear_buffer

extern printf

section .data
  msg db "%ld", 10, 0


section .text

; flip sign on 64 bit
%macro ABS64 1
    neg %1
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
; stack -  the width of the buffer ; on the stack *
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
  xor r10, r10

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
    SWAP rbx, rcx
    SWAP r8, r9
    mov r10, 1
not_steep:

  ; change smallest -> largest
  cmp rbx, r8 
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

  ; rbx  start x
  ; rcx  start y
  ; r8 end x
  ; r9 end y
  cmp r10, 1
  je was_steep
  mov rax, r15
  mul rcx
  add rax, rbx
  jmp was_steep_merge
was_steep:
  mov rax, rbx
  imul rax, r15
  add rax, rcx
was_steep_merge:
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
; r8 - the x coordinate
; r9  - the width of the buffer
write_pixel:
  PROLOGUE

  mov rax, r9
  mul rcx
  add rax, r8
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

;;;;;;;;;;;;


; rdi - is a pointer to the buffer
; rsi - the color to clear with
; rdx - start x
; rcx - start y
; r8 - end x  
; r9 - end y 
; stack - the width of the buffer

write_unfilled_quad:
  PROLOGUE

; rdi -  is a pointer to the buffer
; rsi -  is the color to place (32 bit) 
; rdx -  the start x cordinate
; rcx -  the start y coordinate
; r8  -  the end x coordinate
; r9  -  the end y coordinate
; stack -  the width of the buffer ; on the stack *

  sub rsp, 48
  mov rax, [rbp + 16]
  mov [rsp], rax
  mov [rsp + 8], rdx
  mov [rsp + 16], rcx
  mov [rsp + 24], r8
  mov [rsp + 32], r9

  ; start x, start y -> end x start y
  mov r9, rcx
  call write_line

  ; start x, start y -> start x end y
  mov rdx,  [rsp + 8]
  mov rcx,  [rsp + 16]
  mov r8,   [rsp + 8]
  mov r9,   [rsp + 32]
  call write_line

  ; end x, start y -> end x end y
  mov rdx,  [rsp + 24]
  mov rcx,  [rsp + 16]
  mov r8,   [rsp + 24]
  mov r9,   [rsp + 32]
  call write_line
  ; start x, end y -> end x end y
  mov rdx,  [rsp + 8]
  mov rcx,  [rsp + 32]
  mov r8,   [rsp + 24]
  mov r9,   [rsp + 32]
  call write_line


  EPILOGUE

; rsi -  is a pointer to the buffer
; rax -  is the color to place (32 bit) 
; rdx -  the start x cordinate
; rcx -  the start y coordinate
; r8  -  the end x coordinate
; r9  -  the end y coordinate
; stack -  the width of the buffer ; on the stack *
write_filled_quad:
  PROLOGUE

  ; rbx  - x count
  ; rsi  -  current pointer
  ; r9   - end pointer
  ; r10  - width * 4

  mov rbx, r8
  sub rbx, rdx

  ; just the start x offset in 
  lea rsi, [rsi + rdx * 4]

  ; the width of a buffer * 4
  mov r10, [rbp + 16]
  lea r10, [r10 * 4]

  ; end pointer
  imul r9, r10
  lea r9, [rsi + r9]

  ; start pointer
  imul r8, rcx
  lea rsi, [rsi + r8]

  
  filled_quad_head:
  cmp rsi, r9
  je filled_quad_merge

  mov rdi, rsi
  mov rcx, rbx
  rep stosd

  add rsi, r10
  jmp filled_quad_head
  filled_quad_merge:

  EPILOGUE
  

; rdi - is a pointer to the buffer
; rsi - the color to clear with
; rdx - orig x
; rcx - orig y
; r8  - r
; r9  - the width of the buffer
write_filled_circle:
  
  PROLOGUE
  sub rsp, 16
  mov [rsp], r12
  mov [rsp], r13

  ; rbx r squared
  mov rbx, r8
  imul rbx, rbx

  ; r10 x
  mov r10, r8
  neg r10
circle_x_head:
  cmp r8, r10
  jl circle_x_merge

  ; calc x diff
  mov r13, r10
  imul r13, r13
  ; r11 y
  mov r11, r8
  neg r11
circle_y_head:
  cmp r8, r11
  jl circle_y_merge

  ; calc y diff
  mov rax, r11
  imul rax, rax
  add rax, r13

  ; check if within r_squared
  cmp rbx, rax
  jl circle_y_update

  lea r12, [r11 + rcx]
  imul r12, r9
  lea rax, [r10 + rdx]
  add rax, r12

  mov DWORD [rdi + rax * 4], esi
circle_y_update:
  inc r11
  jmp circle_y_head
circle_y_merge:
  inc r10
  jmp circle_x_head
circle_x_merge:
  mov r12, [rsp]

  EPILOGUE
