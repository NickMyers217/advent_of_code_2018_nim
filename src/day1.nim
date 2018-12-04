import sequtils, strutils, intsets

proc parseInput*(data: string): seq[int] =
  ## Parse the many lines of problem input into a seq of ints
  result = @[]
  for line in splitLines(data):
    if line.strip() != "":
      result.add(line.parseInt())

proc calcFrequency*(data: seq[int], start = 0): int =
  ## Calculate the final frequency of data
  foldl(data, a + b, start)

proc firstRecurringFrequency*(data: seq[int]): int =
  ## Find the first frequency that occurs twice during the caclulation of data's final frequency
  ## If no duplicate frequency is found, take the final frequency as the starting point and try again

  # The set of already seen frequencies
  # We need to import IntSet for this because native nim sets only support up to int16, which is not enough
  var seen: IntSet = initIntSet()

  var nextFrequency = 0
  seen.incl(nextFrequency)

  while true:
    var curFrequency = nextFrequency
    for n in data:
      curFrequency += n
      if seen.contains(curFrequency):
        return curFrequency
      else:
        seen.incl(curFrequency)
    nextFrequency = curFrequency

proc getPartOneAnswer*(inputFile: string): int =
  ## Cacluate the answer for part 1
  inputFile
    .readFile()
    .parseInput()
    .calcFrequency()

proc getPartTwoAnswer*(inputFile: string): int =
  ## Cacluate the answer for part 2
  inputFile
    .readFile()
    .parseInput()
    .firstRecurringFrequency()

when isMainModule:
  echo getPartOneAnswer("res/day1.txt")
  echo getPartTwoAnswer("res/day1.txt")
