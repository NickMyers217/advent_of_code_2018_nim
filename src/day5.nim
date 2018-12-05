import strutils, threadpool, sequtils

proc isReaction*(unit: string): bool =
  ## Determine if a unit is going to react
  assert unit.len() == 2
  # capital letters are 32 spaces behind their lowercase counterparts on the ascii table
  result =
    cmpIgnoreCase($unit[0], $unit[1]) == 0 and abs(ord(unit[0]) - ord(unit[1])) == 32

iterator unitPairs*(polymer: string): (int, string) =
  ## Yield each unit pair of a polymer along with its index
  for i in 0 .. polymer.len()-2:
    yield (i, polymer.substr(i, i+1))

proc eliminate*(polymer: string, aType: char): string =
  ## Removes every instance of `type` from `polymer`
  result = ""
  for c in polymer:
    if cmpIgnoreCase($c, $aType) != 0: result &= c

# TODO: this is wayyyyyy too slow
proc trigger*(polymer: var string, reactionCount: int = 0): void =
  ## Triggers up to `reactionCount` reactions and shortens `polymer` accordingly
  ## the reactions will stop if they are exhausted
  ## if 0 is provided as the count, the polymer will exhaust all its reactions
  var itsTimeToStop = false
  while not itsTimeToStop:
    var reactions = 0
    for i, unit in polymer.unitPairs():
      if unit.isReaction():
        polymer.delete(i, i+1)
        reactions += 1
        break

    # We need to stop if there were no reactions this time, or we hit the count
    if reactions == 0 or (reactionCount > 0 and reactions >= reactionCount):
      itsTimeToStop = true

proc compact*(polymer:string, aType: char, output: bool = true): int =
  ## Returns the length of the polymer left over after removing `aType` and fully reacting
  if output: echo "Compacting " & aType & "..."
  var copy = polymer.eliminate(aType)
  copy.trigger()
  if output:
    echo "Finished compacting " & aType & " with len " & $copy.len()
  result = copy.len() - 1

proc findMostCompact*(polymer: string, output: bool = true): int =
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
  polymer.trigger()
  echo polymer.len() - 1

  var anotherPolymer = input
  echo anotherPolymer.findMostCompact()

when isMainModule:
  printAnswers("res/day5.txt")