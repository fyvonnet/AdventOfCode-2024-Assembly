all: day01 day01-binsearch day02 day03 day04 day05 day06 day07 day08-part1 day08-part2 day09 day10 day11 day12 day13

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

day05: day05.o misc.o stdio.o quicksort.o binsearch.o
	ld -g -o day05 day05.o misc.o stdio.o quicksort.o binsearch.o

day06: day06.o misc.o stdio.o memory.o redblacktree.o
	ld -g -o day06 day06.o misc.o stdio.o memory.o redblacktree.o

day07: day07.o misc.o stdio.o
	ld -g -o day07 day07.o misc.o stdio.o

day08-part1: day08-part1.o misc.o stdio.o quicksort.o memory.o redblacktree.o
	ld -g -o day08-part1 day08-part1.o misc.o stdio.o quicksort.o memory.o redblacktree.o

day08-part2: day08-part2.o misc.o stdio.o quicksort.o memory.o redblacktree.o
	ld -g -o day08-part2 day08-part2.o misc.o stdio.o quicksort.o memory.o redblacktree.o

day09: day09.o misc.o stdio.o
	ld -g -o day09 day09.o misc.o stdio.o

day10: day10.o misc.o stdio.o queue.o
	ld -g -o day10 day10.o misc.o stdio.o queue.o

day11: day11.o misc.o stdio.o memory.o redblacktree.o
	ld -g -o day11 day11.o misc.o stdio.o memory.o redblacktree.o

day12: day12.o misc.o stdio.o quicksort.o memory.o redblacktree.o queue.o
	ld -g -o day12 day12.o misc.o stdio.o quicksort.o memory.o redblacktree.o queue.o 

day13: day13.o quicksort.o misc.o stdio.o memory.o redblacktree.o
	ld -g -o day13 day13.o quicksort.o misc.o stdio.o memory.o redblacktree.o

%.o: %.asm
	as -march=rv64imafdcv -g $< -o $@
