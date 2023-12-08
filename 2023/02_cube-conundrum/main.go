package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
)

const (
	RED   = "red"
	GREEN = "green"
	BLUE  = "blue"
)

func main() {
	data, err := os.ReadFile("input.txt")
	if err != nil {
		log.Fatal(err)
	}

	lines := strings.Split(strings.Trim(string(data), "\n"), "\n")

	partOne(lines)
	partTwo(lines)
}

func partOne(lines []string) {
	targetBag := map[string]int{
		RED:   12,
		GREEN: 13,
		BLUE:  14,
	}

	sum := 0
	for _, line := range lines {
		game := strings.Split(line, ": ")[0]
		sets := strings.Split(strings.Split(line, ": ")[1], "; ")

		gameID, err := strconv.ParseInt(strings.TrimPrefix(game, "Game "), 10, 64)
		if err != nil {
			log.Fatal(err)
		}

		bag := make(map[string]int)
		validCount := 0
		for _, set := range sets {
			cubes := strings.Split(set, ", ")

			for _, cube := range cubes {
				number, err := strconv.ParseInt(strings.Split(cube, " ")[0], 10, 64)
				if err != nil {
					log.Fatal(err)
				}
				cubeColor := strings.Split(cube, " ")[1]

				bag[cubeColor] = int(number)
			}

			if bag[RED] <= targetBag[RED] &&
				bag[GREEN] <= targetBag[GREEN] &&
				bag[BLUE] <= targetBag[BLUE] {
				validCount++
			}
		}

		if validCount == len(sets) {
			sum += int(gameID)
		}
	}

	fmt.Printf("sum: %v\n", sum)
}

func partTwo(lines []string) {
	sum := 0

	for _, line := range lines {
		game := strings.Split(line, ": ")[0]
		sets := strings.Split(strings.Split(line, ": ")[1], "; ")

		gameID, err := strconv.ParseInt(strings.TrimPrefix(game, "Game "), 10, 64)
		if err != nil {
			log.Fatal(err)
		}
		_ = gameID

		bag := make(map[string]int)
		for _, set := range sets {
			cubes := strings.Split(set, ", ")

			for _, cube := range cubes {
				number, err := strconv.ParseInt(strings.Split(cube, " ")[0], 10, 64)
				if err != nil {
					log.Fatal(err)
				}
				cubeColor := strings.Split(cube, " ")[1]

				if bag[cubeColor] < int(number) {
					bag[cubeColor] = int(number)
				}
			}
		}

		power := 1
		for _, number := range bag {
			power *= number
		}

		sum += power
	}

	fmt.Printf("sum: %v\n", sum)
}
