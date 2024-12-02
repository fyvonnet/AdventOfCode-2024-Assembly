all: day01 day02

day01: day01.o quicksort.o misc.o stdio.o memory.o redblacktree.o
	ld -o day01 day01.o quicksort.o misc.o stdio.o memory.o redblacktree.o

day02: day02.o misc.o stdio.o
	ld -o day02 day02.o misc.o stdio.o

%.o: %.asm
	as -march=rv64imafd -g $< -o $@
