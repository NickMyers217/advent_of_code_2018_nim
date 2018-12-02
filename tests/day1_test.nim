import src/day1

const testData = """
+10
-2
-1
"""

let parsedInput = parseInput(testData)
doAssert parsedInput == @[10, -2, -1]

let frequency = calcFrequency(parsedInput)
doAssert frequency == 7

echo("==> Part 1 Answer: ", partOneAnswer("res/day1.txt"))

doAssert firstRecurringFrequency(@[1, -1]) == 0
doAssert firstRecurringFrequency(@[3, 3, 4, -2, -4]) == 10
doAssert firstRecurringFrequency(@[-6, 3, 8, 5, -6]) == 5
doAssert firstRecurringFrequency(@[7, 7, -2, -7, -4]) == 14

echo("==> Part 2 Answer: ", partTwoAnswer("res/day1.txt"))

