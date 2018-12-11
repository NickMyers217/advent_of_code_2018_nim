import strscans, strutils, tables, sequtils

## Hard coded size of the grids width and height
const GRID_SIZE = 500

type
  ## A 2d vector
  Vec* = tuple[x, y: int]

  ## A 2d grid
  Grid* = ref object
    # A list of points that are on this grid
    points*: seq[Vec]
    # A 2d grid of values
    values*: array[GRID_SIZE, array[GRID_SIZE, int]]

proc initVec*(input: string): Vec =
  ## Parse a Vec from a string
  var x, y: int
  discard input.scanf("$i, $i", x, y)
  result = (x, y)

proc `-`*(vec1: Vec, vec2: Vec): Vec =
  ## Vector subtraction
  result = (vec1.x - vec2.x, vec1.y - vec2.y)

proc manhattan*(vec1: Vec, vec2: Vec): int =
  ## Calculate the manhattan distance between 2 Vecs
  let diffVec = vec1 - vec2
  result = abs(diffVec.x) + abs(diffVec.y)

proc newGrid*(points: seq[Vec]): Grid =
  ## Create a new grid
  result = Grid()
  result.points = points

proc markClosest*(grid: var Grid) =
  # Mark each grid location with the index of its closest point in `points`
  # or -1 if there were multiple
  for y in 0 ..< GRID_SIZE:
    for x in 0 ..< GRID_SIZE:
      let curPoint: Vec = (x, y)
      var
        nearest = GRID_SIZE * 2 + 1 # Nothing on the grid can be farther
        val = -1
      for i, p in grid.points:
        var dist = manhattan(p, curPoint)
        if dist == nearest: val = -1
        elif dist < nearest:
          nearest = dist
          val = i
      grid.values[y][x] = val

proc markPointsWithTotalLessThan*(grid: var Grid, amount: int = 10000) =
  # Mark each grid location whose total manhattan distance to all `points` is
  # less than `amount` with a 1, and all others with a -1
  for y in 0 ..< GRID_SIZE:
    for x in 0 ..< GRID_SIZE:
      let total = grid.points
        .map(proc(e: Vec): int = manhattan(e, (x, y)))
        .foldl(a + b)
      if total < amount: grid.values[y][x] = 1
      else: grid.values[y][x] = -1

proc getInfinites*(grid: Grid): set[0..65535] =
  ## Determines which `points` will have infinite areas by walking the
  ## perimeter of the grid
  result = {}
  assert grid.values[0].len() == GRID_SIZE and grid.values.len() == GRID_SIZE
  for x in 0 ..< GRID_SIZE:
    let
      topVal = grid.values[0][x]
      botVal = grid.values[GRID_SIZE - 1][x]
    if topVal > -1: result.incl(topVal)
    if botVal > -1: result.incl(botVal)
  for y in 0 ..< GRID_SIZE:
    let
      leftVal = grid.values[y][0]
      rightVal = grid.values[y][GRID_SIZE - 1]
    if leftVal > -1: result.incl(leftVal)
    if rightVal > -1: result.incl(rightVal)

proc largestArea*(grid: Grid): int =
  ## Determine the area of the largest non-infinite point
  let infinites = grid.getInfinites()
  var counts = initCountTable[int]()
  for y in 1 .. GRID_SIZE - 2:
    for x in 1 .. GRID_SIZE - 2:
      let pointId = grid.values[y][x]
      if pointId > -1 and pointId notin infinites:
        discard counts.getOrDefault(pointId)
        counts.inc(pointId)
  result = counts.largest.val

proc safeArea*(grid: Grid): int =
  ## Determine the area of the safe zone
  result = 0
  for y in 0 ..< GRID_SIZE:
    for x in 0 ..< GRID_SIZE:
      if grid.values[y][x] == 1: inc result

proc printAnswers*(filePath: string) =
  let points = readFile(filePath)
    .splitLines()
    .filter(proc(e: string): bool = e != "")
    .map(initVec)

  var grid = newGrid(points)
  grid.markClosest()
  echo grid.largestArea()

  var anotherGrid = newGrid(points)
  anotherGrid.markPointsWithTotalLessThan()
  echo anotherGrid.safeArea()

when isMainModule:
  printAnswers("res/day6.txt")

