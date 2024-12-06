all: day01 day01-binsearch day02 day03 day04 day05 day06

day01: day01.o quicksort.o misc.o stdio.o memory.o redblacktree.o
	ld -g -o day01 day01.o quicksort.o misc.o stdio.o memory.o redblacktree.o

day01-binsearch: day01-binsearch.o misc.o quicksort.o stdio.o binsearch.o
	ld -g -o day01-binsearch day01-binsearch.o misc.o quicksort.o stdio.o binsearch.o

day02: day02.o misc.o stdio.o
	ld -g -o day02 day02.o misc.o stdio.o

day03: day03.o misc.o stdio.o
	ld -g -o day03 day03.o misc.o stdio.o

day04: day04.o misc.o stdio.o
	ld -g -o day04 day04.o misc.o stdio.o

day05: day05.o misc.o stdio.o memory.o redblacktree.o
	ld -g -o day05 day05.o misc.o stdio.o memory.o redblacktree.o

day06: day06.o misc.o stdio.o memory.o redblacktree.o
	ld -g -o day06 day06.o misc.o stdio.o memory.o redblacktree.o

%.o: %.asm
	as -march=rv64imv -g $< -o $@
