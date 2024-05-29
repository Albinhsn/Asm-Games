

global write_pixel
global clear_buffer

extern printf

section .data


section .text

; rdi - is a pointer to the buffer
; rsi - is the color to place of an int
; rcx - the y coordinate
; r8  - the width of the buffer
; r9 - the x coordinate
write_pixel:

  push rbp
  mov rbp, rsp

  mov rax, r8
  mul rcx
  add rax, r9
  imul rax, 4

  mov DWORD [rdi + rax], esi

  mov rsp, rbp
  pop rbp 
  ret

; rdi - is a pointer to the buffer
; rsi - width of the buffer
; rdx - height of the buffer
; rcx - the color to clear with
clear_buffer:
  
  push rsp
  mov rbp, rsp

  mov rax, rsi
  mov rcx, rdx
  mul rcx
  mov rcx, rax
  mov rax, 0xFFFFFFFF
  rep stosd

  mov rsp, rbp
  pop rbp 
  ret
