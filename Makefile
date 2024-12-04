all: day01 day01-binsearch day02 day03 day04-part1 day04-part2

day01: day01.o quicksort.o misc.o stdio.o memory.o redblacktree.o
	ld -o day01 day01.o quicksort.o misc.o stdio.o memory.o redblacktree.o

day01-binsearch: day01-binsearch.o misc.o quicksort.o stdio.o binsearch.o
	ld -o day01-binsearch day01-binsearch.o misc.o quicksort.o stdio.o binsearch.o

day02: day02.o misc.o stdio.o
	ld -o day02 day02.o misc.o stdio.o

day03: day03.o misc.o stdio.o
	ld -o day03 day03.o misc.o stdio.o

day04: day04.o misc.o stdio.o
	ld -o day04 day04.o misc.o stdio.o

day04-part1: day04-part1.o misc.o stdio.o
	ld -o day04-part1 day04-part1.o misc.o stdio.o

day04-part2: day04-part2.o misc.o stdio.o
	ld -o day04-part2 day04-part2.o misc.o stdio.o

%.o: %.asm
	as -march=rv64imv -g $< -o $@
