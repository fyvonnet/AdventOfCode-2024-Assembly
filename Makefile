all: day01

day01: day01.o quicksort.o misc.o stdio.o memory.o redblacktree.o
	ld -o day01 day01.o quicksort.o misc.o stdio.o memory.o redblacktree.o

%.o: %.asm
	as -march=rv64imafd -g $< -o $@
