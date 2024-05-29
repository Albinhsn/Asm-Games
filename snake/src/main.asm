global main 
extern printf
extern init_sdl_window
extern cleanup_sdl 

section .data:
  m db "Hello World!", 10, 0
  buffer_size equ 1

section .bss
  input resb buffer_size

section .text
  main: 
  
  sub rsp, 24
  lea rdi, [rsp] ; buffer 
  lea rsi, [rsp + 8] ; window
  mov rdx, 620
  mov rcx, 480

  call init_sdl_window

  mov rax, 3
  mov rbx, 1
  mov rcx, input
  mov rdx, buffer_size
  int 0x80

  lea rdi, [rsp + 8]
  call cleanup_sdl 

  mov rax, 1
  mov rbx, 0
  int 0x80
