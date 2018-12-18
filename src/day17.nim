import strutils, sequtils, strscans

type
  ## A 2d vector
  Vec = tuple[x, y: int]
  ## The different states a cell can be in
  Cell* = enum Sand, Spring, Clay, FlowingWater, RestingWater
  ## A 2D grid of cells
  Map = seq[seq[Cell]]
  Grid = ref object
    minBounds, maxBounds: Vec
    padding, width, height: int
    springLocation: Vec
    map: Map

## Vector math helpers
proc `-`(a, b: Vec): Vec {.inline.} = (x: a.x - b.x, y: a.y - b.y)
proc `+`(a, b: Vec): Vec {.inline.} = (x: a.x + b.x, y: a.y + b.y)
proc `*`(a: int, b: Vec): Vec {.inline.} = (x: a * b.x, y: a * b.y)
proc inc(a: var Vec, b: Vec) {.inline.} = a = a + b
proc dec(a: var Vec, b: Vec) {.inline.} = a = a - b
proc down(a: Vec): Vec {.inline.} = a + (0,1)
proc up(a: Vec): Vec {.inline.} = a - (0,1)
proc right(a: Vec): Vec {.inline.} = a + (1,0)
proc left(a: Vec): Vec {.inline.} = a - (1,0)

proc parseLine(line: string): seq[Vec] =
  ## Parse a single line from the input into the list of points it represents
  result = newSeq[Vec]()
  var
    leftAxis, rightAxis: string
    parent, rangeBegin, rangeEnd: int
  if line.scanf("$w=$i, $w=$i..$i", leftAxis, parent, rightAxis, rangeBegin, rangeEnd):
    for n in rangeBegin .. rangeEnd:
      if leftAxis == "y": result.add((n, parent))
      elif leftAxis == "x": result.add((parent, n))
  else:
    echo "Couldn't parse line: ", line
    assert false

proc parseInput*(input: string): seq[Vec] =
  ## Parse the whole input into the full list of clay points
  result = newSeq[Vec]()
  let lines = input.splitLines().filterIt(it != "")
  for line in lines:
    result = result.concat(parseLine(line))

proc `$`*(grid: Grid): string =
  ## Render the grid as a string
  result = ""
  for row in grid.map:
    for cell in row:
      case cell
      of Spring: result &= '+'
      of Sand: result &= '.'
      of Clay: result &= '#'
      of FlowingWater: result &= '|'
      of RestingWater: result &= '~'
    result &= "\n"

proc pointToIndexes(grid: Grid, vec: Vec): Vec {.inline.} =
  ## Convert point space to grid indexes
  result = (vec.x - grid.minBounds.x + grid.padding, vec.y)

proc indexesToPoint(grid: Grid, vec: Vec): Vec {.inline.} =
  ## Convert grid indexes to point space
  result = (vec.x + grid.minBounds.x - grid.padding, vec.y)

proc isOnMap(grid: Grid, vec: Vec): bool {.inline.} =
  ## Check if a given set of indexes are actually on the grid
  let (x, y) = vec
  if x >= 0 and x < grid.width and y >= 0 and y < grid.height:
    return true
  else:
    echo "$1 was not within $2, $3: " % [ $vec, $grid.width, $grid.height ]
    return false

proc getCell(grid: Grid, vec: Vec): Cell {.inline.} =
  ## Retrieve a cell
  assert grid.isOnMap(vec)
  result = grid.map[vec.y][vec.x]

proc setCell(grid: var Grid, vec: Vec, cell: Cell) {.inline.} =
  ## Set a cell
  assert grid.isOnMap(vec)
  grid.map[vec.y][vec.x] = cell

proc cellIsIn(grid: Grid, vec: Vec, types: set[Cell]): bool {.inline.}=
  ## Checks if the value of the cell located at `vec` is within the set of `types`
  result = grid.getCell(vec) in types

proc cellNotIn(grid: Grid, vec: Vec, types: set[Cell]): bool {.inline.}=
  ## Checks if the value of the cell located at `vec` is NOT in the set of `types`
  result = not (grid.getCell(vec) in types)

proc newGrid*(springLocation: Vec, clayLocations: seq[Vec]): Grid =
  ## Create a new grid
  var
    minBounds: Vec = (high(int), high(int))
    maxBounds: Vec = (low(int), low(int))
  for vec in clayLocations:
    if vec.x < minBounds.x: minBounds.x = vec.x
    if vec.x > maxBounds.x: maxBounds.x = vec.x
    if vec.y < minBounds.y: minBounds.y = vec.y
    if vec.y > maxBounds.y: maxBounds.y = vec.y
  var
    padding = 3
    width = (maxBounds.x - minBounds.x) + 1 + (padding * 2)
    height = maxBounds.y + 1 + padding
    map = newSeqWith(height, newSeq[Cell](width))
  result = Grid(
    minBounds: minBounds, maxBounds: maxBounds,
    padding: padding, width: width, height: height,
    springLocation: springLocation,
    map: map
  )
  assert result.map.len == height and result.map[0].len == width
  result.springLocation = result.pointToIndexes(result.springLocation)
  result.setCell(result.springLocation, Spring)
  for vec in clayLocations:
    result.setCell(result.pointToIndexes(vec), Clay)

proc findEdges(grid: Grid, vec, direction: Vec): (bool, Vec) =
  ## Spreads water horizontally as far as it can go
  ## return a bool to let us know if the water has gone over an edge and will fall
  ## as well as the location of the last point it was able to spread to
  var next = vec
  while grid.cellNotIn(next + direction, { Clay }):
    inc next, direction
    if grid.cellNotIn(next.down, { Clay, RestingWater }):
      return (true, next)
  result = (false, next)

proc fill(grid: var Grid, vec: Vec): seq[Vec] =
  ## Fill up a bucket starting at `vec` and return a list of points where
  ## the water will overflow and begin to fall
  result = newSeq[Vec]()
  var
    fillingAt = vec
    rising = true
  while rising:
    let
      (lFell, lVec) = grid.findEdges(fillingAt, (-1, 0))
      (rFell, rVec) = grid.findEdges(fillingAt, ( 1, 0))
    if lFell:
      result.add lVec
      rising = false
    if rFell:
      result.add rVec
      rising = false
    if (not lFell) and (not rFell):
      fillingAt = fillingAt.up
    for s in 0 .. abs(rVec.x - lVec.x):
      if lFell or rFell:
        grid.setCell(rVec - (s * (1, 0)), FlowingWater)
      else:
        grid.setCell(rVec - (s * (1, 0)), RestingWater)

proc dropWater*(grid: var Grid) =
  ## Drops all the water down until all the streams reach the bottom
  var dropFrom: seq[Vec] = @[ grid.springLocation ]
  while dropFrom.len > 0:
    var waterLoc = dropFrom.pop().down
    while waterLoc.y <= grid.maxBounds.y and grid.cellNotIn(waterLoc, { Clay, RestingWater }):
      grid.setCell(waterLoc, FlowingWater)
      inc waterLoc, (0,1)

    dec waterLoc, (0,1)
    if grid.cellIsIn(waterLoc.left,  { FlowingWater }) and
       grid.cellIsIn(waterLoc.right, { FlowingWater }):
      continue
    elif grid.cellIsIn(waterLoc.down, { Sand }):
      continue

    dropFrom = dropFrom.concat(grid.fill(waterLoc))

proc countWater*(grid: Grid, types: set[Cell] = { FlowingWater, RestingWater }): int =
  ## Count all of the water cells who have values within the set `types`
  result = 0
  for y in 0 ..< grid.height:
    if y < grid.minBounds.y or y > grid.maxBounds.y:
      continue
    for x in 0 ..< grid.width:
      if grid.cellIsIn((x, y), types):
        inc result

when isMainModule:
  let input = readFile("res/day17.txt")
  var grid = newGrid((500, 0), parseInput(input))
  grid.dropWater()
  echo grid
  echo grid.countWater()
  echo grid.countWater({ RestingWater })
