
#include <SDL2/SDL.h>
#include <SDL2/SDL_render.h>
#include <SDL2/SDL_surface.h>
#include <SDL2/SDL_video.h>
#include <cstdint>

void sta_init_sdl_window(unsigned char **buffer, SDL_Window **window,
                         uint64_t screenWidth, uint64_t screenHeight) {
  SDL_Init(SDL_INIT_VIDEO);
  *window = SDL_CreateWindow("Window", 0, 0, screenWidth, screenHeight, 0);

  SDL_Surface *surface = SDL_GetWindowSurface(*window);
  *buffer = (unsigned char *)surface->pixels;
}

void render(SDL_Window *window) { SDL_UpdateWindowSurface(window); }
