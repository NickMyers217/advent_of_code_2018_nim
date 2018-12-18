import strutils, sequtils, tables

type
  ## A 2d vector
  Vec = tuple[x, y: int]
  ## Cell types
  Cell = enum Open, Tree, Lumberyard
  ## GOL (Game Of Life)
  GOL = seq[seq[Cell]]

proc `-`(a, b: Vec): Vec {.inline.} = (x: a.x - b.x, y: a.y - b.y)
proc `+`(a, b: Vec): Vec {.inline.} = (x: a.x + b.x, y: a.y + b.y)

proc parseInput(input: string): GOL =
  var lines = input.splitLines.filterIt(it != "")
  result = newSeqWith(lines.len, newSeq[Cell](lines[0].len))
  for y, row in lines:
    for x, col in row:
      case col
      of '.': result[y][x] = Open
      of '|': result[y][x] = Tree
      of '#': result[y][x] = Lumberyard
      else: discard

proc `$`(gol: GOL): string =
  result = ""
  for row in gol:
    for col in row:
      case col
      of Open: result &= '.'
      of Tree: result &= '|'
      of Lumberyard: result &= '#'
    result &= '\n'

const neighbors: array[8, Vec] = [
  (-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1)
]
proc nextMinute(gol: GOL): GOL =
  result = newSeqWith(gol.len, newSeq[Cell](gol[0].len))
  for y, row in gol:
    for x, _ in row:
      var cells = newSeq[Cell]()
      for dir in neighbors:
        let (nX, nY) = (x,y) + dir
        if nY >= 0 and nY < gol.len and nX >= 0 and nX < gol[0].len:
          cells.add(gol[nY][nX])
      case gol[y][x]
      of Open:
        if cells.count(Tree) >= 3: result[y][x] = Tree
        else: result[y][x] = Open
      of Tree:
        if cells.count(Lumberyard) >= 3: result[y][x] = Lumberyard
        else: result[y][x] = Tree
      of Lumberyard:
        if cells.count(Lumberyard) >= 1 and cells.count(Tree) >= 1: result[y][x] = Lumberyard
        else: result[y][x] = Open

proc advanceNMinutes(gol: GOL, n: int): GOL =
  result = gol
  for i in 0 ..< n:
    result = result.nextMinute()

proc getResourceValue(gol: GOL): int =
  var
    trees = 0
    lumberyards = 0
  for y, row in gol:
    for x, _ in row:
      if gol[y][x] == Tree: inc trees
      elif gol[y][x] == Lumberyard: inc lumberyards
  result = trees * lumberyards

proc getResourceValueOfHughMungus(gol: GOL, n: int, debug = false): GOL =
  result = gol
  var
    table = initTable[int, int]() # resourceValue => index
    repeatCount = 0
    sameForNIterations = 0
    finalI = 0
    finalVal = 0
  for i in 0 ..< n:
    let val = result.getResourceValue()
    if table.hasKeyOrPut(val, i):
      if debug:
        debugEcho "Pattern repeated after ", i - table[val], " iterations!"
      if repeatCount == i - table[val]:
        inc sameForNIterations
      else:
        sameForNIterations = 0
        repeatCount = i - table[val]
      if sameForNIterations > 10 and (i mod int(n / 1_000_000) == 0):
        finalI = i
        finalVal = val
        break
      table[val] = i
    result = result.nextMinute()

  if debug:
    debugEcho "Cycle detected at ", repeatCount, " iterations"
    debugEcho "Final value at iteration ", finalI, " was ", finalVal
    debugEcho "Verify the val will be the same ", repeatCount, " iterations from now"

  for i in 0 ..< repeatCount:
    result = result.nextMinute()

  if debug:
    debugEcho "Does the previous val ", finalVal, " equal ", result.getResourceValue()
    debugEcho "If so, that is the answer!"

when isMainModule:
  let input = readFile("res/day18.txt")
  let testInput = """
.#.#...|#.
.....#|##|
.|..|...#.
..|#.....#
#.#|||#|#|
...#.||...
.|....|...
||...#|.#|
|.||||..|.
...#.|..|."""

  let
    gol = parseInput(input)
    ten = gol.advanceNMinutes(10)
  echo ten.getResourceValue()

  const BIG_NUM = 1_000_000_000
  let hughMungus = gol.getResourceValueOfHughMungus(BIG_NUM, true)
  echo hughMungus.getResourceValue()

