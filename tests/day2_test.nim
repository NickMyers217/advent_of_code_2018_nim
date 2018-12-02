import sequtils

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

doAssert (not testData[0].hasLetterCount(2)) and (not testData[0].hasLetterCount(3))
doAssert testData[1].hasLetterCount(2) and testData[1].hasLetterCount(3)

doAssert testData.filter(proc(e: string): bool = e.hasLetterCount(2)).len == 4
doAssert testData.filter(proc(e: string): bool = e.hasLetterCount(3)).len == 3

doAssert getChecksum(testData) == 12

echo("==> Answer Part 1: ", getPartOneAnswer("res/day2.txt"))

doAssert getTargetBoxLetters(moreTestData) == "fgij"

echo("==> Answer Part 2: ", getPartTwoAnswer("res/day2.txt"))

