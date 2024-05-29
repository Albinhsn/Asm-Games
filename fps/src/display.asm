

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
  mov rbx, %2
  mov %1, rbx
  mov %2, rax
%endmacro

%macro PROLOGUE
  push rbp
  mov rbp, rsp
%endmacro

%macro EPILOGUE 
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
; r10 -  the width of the buffer
write_line:
  PROLOGUE

  sub rsp, 128
  mov [rsp],      rdi ; pointer to buffer
  mov [rsp + 8],  rsi ; color
  mov [rsp + 16], rdx ; start x
  mov [rsp + 24], rcx ; start y
  mov [rsp + 32], r8  ; end x
  mov [rsp + 40], r9  ; end y 
  mov [rsp + 48], r10 ; width of buffer
  ; [rsp + 56]          steep
  ; [rsp + 64]          dx 
  ; [rsp + 72]          dy
  ; [rsp + 88]          derror
  ; [rsp + 96]          downwards


; check steep
  mov rax, rdx
  sub rax, r8
  ABS64 rax

  mov rbx, rcx
  sub rbx, r9
  ABS64 rbx

  cmp rax, rbx
  jge not_steep
    SWAP [rsp + 16], [rsp + 24] 
    SWAP [rsp + 32], [rsp + 40] 

    mov QWORD [rsp + 56], 1
    jmp steep_merge

not_steep:
  mov QWORD [rsp + 56], 0
steep_merge:

  ; change smallest -> largest
  mov rax, [rsp + 16]
  mov rbx, [rsp + 32]
  cmp rax, rbx
  jle start_is_less 

  SWAP [rsp + 16], [rsp + 32]
  SWAP [rsp + 24], [rsp + 40]

start_is_less:

  ; calculate dy/dx
  ; dx
  mov rax, [rsp  + 32] 
  mov rbx, [rsp  + 16]
  sub rax, rbx
  mov [rsp + 64], rax

  ; dy
  mov rcx, [rsp  + 40] 
  mov rdx, [rsp  + 24]
  sub rcx, rdx
  imul rcx, 2
  cmp rcx, 0
  jge upwards

downwards:
  ABS64 rcx 
  mov QWORD [rsp + 96], -1
  jmp up_merge

upwards:
  mov QWORD [rsp + 96], 1

up_merge:

  mov [rsp + 72], rcx ; dy
  mov QWORD [rsp + 88], 0 ; derror


  ; go from start x to end x
line_loop_head:
  mov rax, [rsp + 16]
  mov rbx, [rsp + 32]
  cmp rax, rbx
  jge line_loop_end


  mov rdi, [rsp]
  
  mov rax, [rsp + 56]
  cmp rax, 1
  je steep_pixel 
  mov rcx, [rsp + 24]
  mov r9,  [rsp + 16]
  
jmp steep_pixel_merge
steep_pixel:
  mov r9, [rsp + 24]
  mov rcx,  [rsp + 16]
  
steep_pixel_merge:

  mov rsi, [rsp + 8]
  mov r8,  [rsp + 48]
  call write_pixel

  mov rax, [rsp + 72]
  mov rbx, [rsp + 88]
  add rax, rbx
  mov rcx, [rsp + 64] ; dx
  mov [rsp + 88], rax
  cmp rax, rcx
  jle increase_y_merge
  
  mov rax, [rsp + 96]
  mov rbx, [rsp + 24]
  add rax, rbx
  mov [rsp + 24], rax
  
  imul rcx, 2
  mov rbx, [rsp + 88] 
  sub rbx, rcx
  mov [rsp + 88], rbx

    
increase_y_merge:
  add QWORD [rsp + 16], 1
  jmp line_loop_head

line_loop_end:

  EPILOGUE

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
