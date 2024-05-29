
extern SDL_Init
extern SDL_CreateWindow
extern SDL_Quit
extern printf
extern SDL_GetWindowSurface
extern SDL_DestroyWindow
extern SDL_DestroyWindowSurface

global init_sdl_window
global cleanup_sdl 

section .data
  window_name db "Window", 0
  msg db "%ld", 10, 0
  m db "Destroyed!", 10, 0

section .text

; rdi unsigned char ** buffer 
; rsi SDL_Window ** Window
; rdx screen_width
; rcx screen_height
init_sdl_window:
  
  push rbp
  mov rbp, rsp

  sub rsp, 32
  mov [rsp], rdi
  mov [rsp + 8], rsi
  mov [rsp + 16], rdx
  mov [rsp + 24], rcx

  mov QWORD rdi, 0x20 ; 20 = SDL_INIT_VIDEO
  call SDL_Init

  mov rdi, window_name
  mov rsi, 0
  mov rdx, 0
  mov rcx, [rsp + 16]
  mov r8,  [rsp + 24]
  call SDL_CreateWindow
  mov rbx, [rsp + 8]
  mov [rbx], rax

  mov rdi, rax
  call SDL_GetWindowSurface ; returns SDL_Surface * surface
  mov rax, [rax + 24] ; the offset into the struct where
  mov rbx, [rsp]
  mov [rbx], rax

  mov rsp, rbp
  pop rbp
  ret

cleanup_sdl:

; rdi - window pointer
  push rbp
  mov rbp, rsp

  sub rsp, 16
  mov [rsp], rdi
  call SDL_DestroyWindowSurface

  mov rdi, [rsp]
  call SDL_DestroyWindow 

  call SDL_Quit

  mov rsp, rbp
  pop rbp
  ret

  
  
