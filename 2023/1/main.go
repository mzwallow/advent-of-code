package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"regexp"
	"strconv"
	"strings"
)

func main() {
	f, err := os.Open("input.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	input, err := io.ReadAll(f)
	if err != nil {
		log.Fatal(err)
	}

	lines := strings.Split(strings.Trim(string(input), "\n"), "\n")

	partOne(lines)
	partTwo(lines)
}

func partOne(lines []string) {
	reg := regexp.MustCompile(`\d`)

	calibrationValue := 0
	for _, line := range lines {
		digits := reg.FindAllString(line, -1)

		firstDigit := digits[0]
		lastDigit := digits[len(digits)-1]

		twoDigitNoStr := fmt.Sprintf("%s%s", firstDigit, lastDigit)

		twoDigitNo, err := strconv.ParseInt(twoDigitNoStr, 10, 64)
		if err != nil {
			log.Fatal(err)
		}

		calibrationValue += int(twoDigitNo)
	}

	fmt.Println(calibrationValue)
}

func partTwo(lines []string) {
	numbers := []string{"one", "two", "three", "four", "five", "six", "seven", "eight", "nine"}

	calibrationValue := 0
	for _, line := range lines {
		digits := make([]string, 0)
		for i, c := range line {
			if isDigit(string(c)) {
				digits = append(digits, string(c))
			}

			for j, n := range numbers {
				if strings.HasPrefix(line[i:], n) {
					digits = append(digits, fmt.Sprint(j+1))
				}
			}
		}

		firstDigit := digits[0]
		lastDigit := digits[len(digits)-1]

		twoDigitNoStr := fmt.Sprintf("%s%s", firstDigit, lastDigit)

		twoDigitNo, err := strconv.ParseInt(twoDigitNoStr, 10, 64)
		if err != nil {
			log.Fatal(err)
		}

		calibrationValue += int(twoDigitNo)
	}

	fmt.Println(calibrationValue)
}

func isDigit(s string) bool {
	return regexp.MustCompile(`\d`).MatchString(s)
}
