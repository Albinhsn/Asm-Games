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
extern write_filled_quad
extern write_filled_circle
extern malloc

%macro PROLOGUE 0
  push rbp
  mov rbp, rsp
%endmacro

%macro EPILOGUE 0
  mov rsp, rbp
  pop rbp
  ret
%endmacro

section .data:
  screen_width equ 620
  screen_height equ 480

  grid_width equ 20
  grid_height equ 20

section .text
  main: 
  
  sub rsp, 40
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

  lea rdi, [rsp + 16]
  call init_map

main_loop:

  ; update window
  mov rdi, [rsp + 8]
  call update_window

  ; reset buffer
  mov rdi, [rsp]
  mov rsi, screen_width
  mov rdx, screen_height
  mov rcx, 0xFFFFFFFF
  call clear_buffer

  ; check if we quit / handle input
  call should_quit
  cmp rax, 1
  jnz main_loop

  lea rdi, [rsp + 8]
  call cleanup_sdl 

  mov rax, 1
  mov rbx, 0
  int 0x80


section .data
  
  map db 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1, 1,1,1,1,1


section .text
; rdi - pointer to the place where we place the buffer, width and height
init_map:
  PROLOGUE

  sub rsp, 16
  mov [rsp], rdi

  ; store it into the struct
  mov QWORD [rdi + 8], grid_width
  mov QWORD [rdi + 16], grid_height 

  ; width and height
  mov rdi, grid_width

  imul rdi, grid_height
  call malloc
  
  mov rsi, [rsp]
  mov [rsi], rax

  mov rcx, grid_width
  imul rcx, grid_height
  lea rsi, [map]
  mov rdi, rax
  rep movsb

  EPILOGUE

