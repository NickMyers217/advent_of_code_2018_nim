import ../src/day1

import unittest

const testData = """
+10
-2
-1
"""

suite "Day 1 tests":
  test "Can parse input":
    let parsedInput = parseInput(testData)
    check(parsedInput == @[10, -2, -1])

  test "Can calculate final frequency":
    let frequency = calcFrequency(parseInput(testData))
    check(frequency == 7)

  test "Can find the first recurring frequency":
    check:
      firstRecurringFrequency(@[1, -1]) == 0
      firstRecurringFrequency(@[3, 3, 4, -2, -4]) == 10
      firstRecurringFrequency(@[-6, 3, 8, 5, -6]) == 5
      firstRecurringFrequency(@[7, 7, -2, -7, -4]) == 14
