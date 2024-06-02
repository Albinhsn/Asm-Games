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
extern sqrt

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
  spawn_position_x dq 2.0
  spawn_position_y dq 2.0
  player_width equ 4
  player_fov dq 75.0
  player_rotation dq 0
  player_color db 0xFF, 0xFF, 0x00, 0xFF
  number_of_rays equ 620
  ray_step_size dq 0.2

  temp_ray_dir_x dq 0
  temp_ray_dir_y dq 0.2

section .text
  main: 
  
  sub rsp, 72
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

  lea rdi, [rsp + 16]
  mov rsi, [rsp]
  mov rcx, screen_width
  mov rdx, screen_height
  call render_debug_map

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
      db 1,0,0,0,0, 0,0,2,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,2,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,2,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,2,0,0, 0,0,0,0,0, 0,0,0,0,1
      db 1,0,0,0,0, 0,0,2,0,0, 0,0,0,0,0, 0,0,0,0,1
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
  mov rax, [spawn_position_x]
  mov QWORD [rdi + 24],  rax
  mov rax, [spawn_position_y]
  mov QWORD [rdi + 32], rax
  mov rax, [player_fov]
  mov QWORD [rdi + 40], rax
  mov rax, [player_rotation]
  mov QWORD [rdi + 48], rax

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


section .data
  COLORS:  db 0xFF,0xFF,0xFF,0xFF
           db 0xFF,0, 0xFF, 0xFF
           db 0xFF,0, 0x0, 0xFF

section .text

; rdi - the pointer to the map
; rsi - pointer to the framebuffer
; rcx - width of the framebuffer
; rdx - height of the framebuffer
render_debug_map:
  PROLOGUE

  sub rsp, 96
  mov [rsp], rdi
  mov [rsp + 8], rsi
  mov [rsp + 16], rcx
  mov [rsp + 24], rdx 

  ; figure out width and height of each grid block 
  mov rax, rcx
  sar rax, 1
  mov rcx, [rdi + 8]
  xor rdx, rdx
  idiv rcx
  mov [rsp + 32], rax ; width of a block

  mov rax, [rsp + 24]
  mov rcx, [rdi + 16]
  xor rdx, rdx
  idiv rcx
  mov [rsp + 40], rax ; height of a block

  mov QWORD [rsp + 48], 0 ; current x

  ; iterate over map and get color of block
render_debug_map_x_head:
  mov rax, [rsp + 48]
  mov rbx, [rsp]
  mov rbx, [rbx + 8]
  cmp rax, rbx
  jge render_debug_map_x_merge

  mov QWORD [rsp + 56], 0 ; current y
render_debug_map_y_head:
  mov rax, [rsp + 56]
  mov rbx, [rsp]
  mov rbx, [rbx + 16]
  cmp rax, rbx
  jge render_debug_map_x_update


  mov rax, [rsp + 56]
  mov rbx, [rsp]
  mov rbx, [rbx + 8]
  imul rax, rbx
  mov rbx, [rsp + 48]
  add rax, rbx
  mov rbx, [rsp]
  mov rbx, [rbx]
  mov BYTE al, [rbx + rax]
  movzx rax, al
  mov DWORD eax, [COLORS + rax * 4]
  mov [rsp + 64], rax

  ; pointer to the buffer
  mov rsi, [rsp + 8]

  mov rdx, [rsp + 48]
  mov rbx, [rsp + 32]
  imul rdx, rbx
  mov r8, [rsp + 32]
  add r8, rdx

  mov rcx, [rsp + 56]
  mov rbx, [rsp + 40]
  imul rcx, rbx
  mov r9, [rsp + 40]
  add r9, rcx

  mov rax, [rsp + 64]
  mov r10, [rsp + 16]

  sub rsp, 16
  mov [rsp], r10

  call write_filled_quad
  add rsp, 16

  add QWORD [rsp + 56], 1
  jmp render_debug_map_y_head

render_debug_map_x_update:
  add QWORD [rsp + 48], 1
  jmp render_debug_map_x_head

render_debug_map_x_merge:

  ; render player
  
  mov rax, [rsp]
  movsd xmm0, [rax + 24]
  mov rsi, [rax + 8]
  mov rcx, [rsp + 16]

  
  call convert_float_position
  sub rsp, 16
  mov [rsp], rax

  mov rax, [rsp + 16]
  movsd xmm0, [rax + 32]
  mov rsi, [rax + 16]
  mov rcx, [rsp + 40]

  call convert_float_position
  mov rcx, rax
  mov rdx, [rsp]
  add rsp, 16
  
  mov r8, player_width
  mov DWORD esi, [player_color]
  mov rdi, [rsp + 8]
  mov r9, [rsp + 16]
; rdi - is a pointer to the buffer
; rsi - the color to clear with
; rdx - orig x
; rcx - orig y
; r8  - r
; r9  - the width of the buffer
  call write_filled_circle

  
  mov rdi, [rsp]
  mov rax, [spawn_position_x]
  movq xmm0, rax
  mov rax, [spawn_position_y]
  movq xmm1, rax
  mov rax, [temp_ray_dir_x]
  movq xmm2, rax
  mov rax, [temp_ray_dir_y]
  movq xmm3, rax

  call cast_ray
  ; xmm0 is x 
  ; xmm1 is y

  ; convert to pixel locations
; xmm0 is the float position
; rsi is grid width/height
; rcx is buffer width/height
; returns result in rax
  call convert_float_position
  call convert_float_position
  call convert_float_position
  call convert_float_position

; rdi -  is a pointer to the buffer
; rsi -  is the color to place (32 bit) 
; rdx -  the start x cordinate
; rcx -  the start y coordinate
; r8  -  the end x coordinate
; r9  -  the end y coordinate
; stack -  the width of the buffer ; on the stack *
  call write_line



  EPILOGUE

; xmm0 is the float position
; rsi is grid width/height
; rcx is buffer width/height
; returns result in rax
convert_float_position:
  ; get total width of block
  ; convert to float 
  ; divide player_x with total
  ; convert the width of the buffer / 2 to float
  ; multiply with the divide result
  ; convert back to int
  ; is orig x
  cvtsi2sd xmm1, rsi
  divsd xmm0, xmm1
  cvtsi2sd xmm1, rcx
  mulsd xmm1, xmm0
  cvtsd2si rax, xmm1

  ret

; rdi map pointer
; rsi x
; rcx y
; returns in rax the tile
get_map_tile: 
  ; width
  mov rax, [rdi + 8]
  imul rcx, rax
  add rsi, rcx
  mov rax, [rdi]
  mov BYTE al, [rax + rsi]
  movsx rax, al

  ret



; rdi map pointer
; xmm0 x position 
; xmm1 y position
; xmm2 ray x direction
; xmm3 ray y direction

; return xmm0 x, xmm1 y
cast_ray:
  PROLOGUE
  
  movsd xmm4, xmm0
  movsd xmm5, xmm1

cast_ray_head:
  addsd xmm0, xmm2
  addsd xmm1, xmm3
  cvtsd2si rsi, xmm0
  cvtsd2si rcx, xmm1
  call get_map_tile
  cmp rax, 0
  je cast_ray_head

  EPILOGUE


