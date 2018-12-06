import strutils, threadpool, sequtils

proc isReaction*(unitA: char, unitB: char): bool =
  ## Determine if a unit pair is going to react
  # capital letters are 32 spaces behind their lowercase counterparts on the ascii table
  result = abs(ord(unitA) - ord(unitB)) == 32

proc isReaction*(unitPair: string): bool =
  assert unitPair.len() == 2
  result = isReaction(unitPair[0], unitPair[1])

proc eliminate*(polymer: string, aType: char): string =
  ## Removes every instance of `type` from `polymer`
  result = polymer.replace($aType, "").replace($aType.toUpperAscii(), "")

proc trigger*(polymer: string): string =
  ## Builds a shortened polymer by exhausting all of the reactions in `polymer`
  var
    chars: seq[char] = @[]
    curIndex = 0
  for unit in polymer:
    if curIndex > 0 and isReaction(unit, chars[chars.high]):
      discard chars.pop()
      curIndex -= 1
    else:
      chars.add(unit)
      curIndex += 1
  result = chars.join()

proc compact*(polymer:string, aType: char, output: bool = true): int =
  ## Returns the length of the polymer left over after removing `aType` and fully reacting
  if output: echo "Compacting " & aType & "..."
  let copy = polymer.eliminate(aType).trigger()
  if output:
    echo "Finished compacting " & aType & " with len " & $copy.len()
  result = copy.len() - 1

proc findMostCompact*(polymer: string, output: bool = false): int =
  ## Find the most compact polymer possible by trying to eliminate a type

  # Compact a polymer using each possible type
  # do it it in paralell to get things dones faster
  var lengths: seq[FlowVar[int]] = @[]
  for aType in 'a' .. 'z':
    lengths.add(spawn polymer.compact(aType, output))
  sync()

  result = polymer.len()
  for l in lengths:
    if ^l < result: result = ^l

proc printAnswers*(filePath: string): void =
  ## Prints the answers!
  let input = readFile(filePath)

  var polymer = input
  echo polymer.trigger().len() - 1

  var anotherPolymer = input
  echo anotherPolymer.findMostCompact()

when isMainModule:
  printAnswers("res/day5.txt")