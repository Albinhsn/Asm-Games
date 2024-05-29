LDFLAGS := -lc -lSDL2
TARGET = main


LIB_SRCS = $(wildcard src/*.asm)
LIB_OBJS = $(patsubst src/%.asm,obj/%.o,$(LIB_SRCS))

g: $(TARGET)
$(TARGET): $(LIB_OBJS)
	gcc -no-pie -o $@ $^ $(LDFLAGS)

obj/%.o: src/%.asm
	@mkdir -p $(@D)
	nasm -f elf64 $< -o $@


clean:
	rm -rf obj/ $(TARGET)

.PHONY: all clean

len:
	find . -name '*.asm' | xargs wc -l
