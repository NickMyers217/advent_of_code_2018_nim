import unittest, sequtils

import src/day2

const
  testData = @[
    "abcdef",
    "bababc",
    "abbcde",
    "abcccd",
    "aabcdd",
    "abcdee",
    "ababab"
  ]

  moreTestData = @[
    "abcde",
    "fghij",
    "klmno",
    "pqrst",
    "fguij",
    "axcye",
    "wvxyz"
  ]

suite "Day 2 tests":
  test "Can determine if a string has letter count 2 or 3":
    check:
      (not testData[0].hasLetterCount(2)) and (not testData[0].hasLetterCount(3))
      testData[1].hasLetterCount(2) and testData[1].hasLetterCount(3)

  test "Can find the correct number of 2 and 3 letter count strings":
    check:
      testData.filter(proc(e: string): bool = e.hasLetterCount(2)).len == 4
      testData.filter(proc(e: string): bool = e.hasLetterCount(3)).len == 3

  test "Can calculate a correct checksum":
    check(getChecksum(testData) == 12)

  test "Can log the answer for part one":
    echo("\t==> Answer Part 1: ", getPartOneAnswer("res/day2.txt"))
    require(true)

  test "Can find the common letters from the correct ids":
    check(getTargetBoxLetters(moreTestData) == "fgij")

  test "Can log the answer for part two":
    echo("\t==> Answer Part 2: ", getPartTwoAnswer("res/day2.txt"))
    require(true)

