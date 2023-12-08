package main

import (
	"fmt"
	"log"
	"os"
	"regexp"
	"strconv"
	"strings"
)

func main() {
	data, err := os.ReadFile("input.txt")
	if err != nil {
		log.Fatal(err)
	}

	lines := strings.Split(strings.Trim(string(data), "\n"), "\n")

	partOne(lines)
}

func partOne(lines []string) {
	regex := regexp.MustCompile(`\d+`)

	partNumberSum := 0

	for i, line := range lines {
		numbersIdxs := regex.FindAllStringIndex(line, -1)

		if len(numbersIdxs) == 0 {
			continue
		}

		for _, numbersIdx := range numbersIdxs {
			for j := numbersIdx[0]; j < numbersIdx[1]; j++ {
				if isAdjacentToSymbol(lines, i, j) {
					partNumber, err := strconv.Atoi(line[numbersIdx[0]:numbersIdx[1]])
					if err != nil {
						log.Fatal(err)
					}

					partNumberSum += int(partNumber)
					break
				}
			}
		}
	}

	fmt.Printf("partNumberSum: %v\n", partNumberSum)
}

func isDigit(char string) bool {
	return regexp.MustCompile(`\d`).MatchString(char)
}

func isAdjacentToSymbol(lines []string, x, y int) bool {
	m := len(lines)
	n := len(lines[0])

	xIdx := 0
	if x > 0 {
		xIdx = -1
	}

	xMax := 1
	if x == m-1 {
		xMax = 0
	}

	yIdx := 0
	if y > 0 {
		yIdx = -1
	}

	yMax := 1
	if y == n-1 {
		yMax = 0
	}

	for i := xIdx; i <= xMax; i++ {
		for j := yIdx; j <= yMax; j++ {
			if i != 0 || j != 0 {
				char := string(lines[x+i][y+j])

				if !isDigit(char) && char != "." {
					return true
				}
			}
		}
	}

	return false
}
