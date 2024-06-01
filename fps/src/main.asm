global main 
extern printf
extern init_sdl_window
extern cleanup_sdl 
extern should_quit
extern clear_buffer
extern update_window
extern write_pixel
extern write_line
extern write_unfilled_quad

section .data:
  screen_width equ 620
  screen_height equ 480


section .text
  main: 
  
  sub rsp, 24
  lea rdi, [rsp]      ; buffer 
  lea rsi, [rsp + 8]  ; window
  mov rdx, screen_width
  mov rcx, screen_height
  call init_sdl_window


  mov rdi, [rsp]
  mov rsi, screen_width
  mov rdx, screen_height
  mov rcx, 0xFFFFFFFF
  call clear_buffer

main_loop:
; rdi -  is a pointer to the buffer
; rsi -  is the color to place (32 bit) 
; rdx -  the start x cordinate
; rcx -  the start y coordinate
; r8  -  the end x coordinate
; r9  -  the end y coordinate
; r10 -  the width of the buffer

  mov rdi, [rsp]
  mov rsi, 0xFF00FFFF
  mov rdx, 0
  mov rcx, 0
  mov r8,  200 
  mov r9, 200
  sub rsp, 16
  mov QWORD [rsp], screen_width
  call write_unfilled_quad
  add rsp, 16

  ; update window
  mov rdi, [rsp + 8]
  call update_window

  ; ; reset buffer
  ; mov rdi, [rsp]
  ; mov rsi, screen_width
  ; mov rdx, screen_height
  ; mov rcx, 0xFFFFFFFF
  ; call clear_buffer

  ; check if we quit / handle input
  call should_quit
  cmp rax, 1
  jnz main_loop

  lea rdi, [rsp + 8]
  call cleanup_sdl 

  mov rax, 1
  mov rbx, 0
  int 0x80
