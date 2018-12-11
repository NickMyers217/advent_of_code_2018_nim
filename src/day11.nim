import strutils, tables

## Hard coded grid width and height
const GRID_SIZE = 300
const GRID_LEN = GRID_SIZE * GRID_SIZE

type
  Point* = tuple[x, y: int]

  Grid* = object
    serial*: int
    powerLevels*: array[GRID_SIZE * GRID_SIZE, int]

func computePower*(point: Point, serial: int): int =
  ## Compute the power level for a given point and serial number
  result = 0
  let
    rackId = point.x + 10
    temp = (rackId * point.y + serial) * rackId
    tempStr = $temp

  if tempStr.len >= 3:
    # The 48 is to account for ascii table conversion
    result = int(tempStr[tempStr.high - 2]) - 48 - 5

func initGrid*(serial: int): Grid =
  ## Get a new grid
  var powerLevels: array[GRID_LEN, int]

  for y in 0 ..< GRID_SIZE:
    for x in 0 ..< GRID_SIZE:
      let
        power = computePower((x + 1, y + 1), serial)
        i = y * GRID_SIZE + x
      assert i >= 0 and i < GRID_LEN
      powerLevels[i] = power

  result = Grid(serial: serial, powerLevels: powerLevels)

func getPower*(grid: Grid, point: Point): int =
  ## Get a power level at a given point
  let i = (point.y - 1) * GRID_SIZE + (point.x - 1)
  assert i >= 0 and i < GRID_LEN
  result = grid.powerLevels[i]

proc getTotalPower*(grid: Grid, cornerPoint: Point, size: int = 3): int =
  ## Gets the total power for a section of size starting at cornerPoint
  ## returns 0 if there is not enough space for a full 3x3 section
  var total = 0
  for yOff in 0 ..< size:
    for xOff in 0 ..< size:
      let p: Point = (cornerPoint.x + xOff, cornerPoint.y + yOff)
      if p.x < 1 or p.x > GRID_SIZE or p.y < 1 or p.y > GRID_SIZE:
        return 0
      else:
        total += grid.getPower(p)
  result = total

func getLargest3x3*(grid: Grid): Point =
  ## Gets the corner point of the 3x3 section with the largest total power
  result = (0, 0)
  var
    largest = 0
    cache = initTable[Point, int]() # a helpful cache
  for y in 1 .. GRID_SIZE:
    for x in 1 .. GRID_SIZE:
      var total: int
      if cache.hasKey((x, y)):
        total = cache[(x, y)]
      else:
        total = grid.getTotalPower((x, y))
        cache.add((x, y), total)
      if total > largest:
        largest = total
        result = (x, y)

func getLargest*(grid: Grid): (Point, int) =
  ## Gets the corner point of any section with the largest total power
  ## also return the size of the section
  var
    largest = 0
    cache = initTable[(Point, int), int]() # a helpful cache
  for y in 1 .. GRID_SIZE:
    for x in 1 .. GRID_SIZE:
      for size in 1 .. GRID_SIZE:
        if x + size > GRID_SIZE or y + size > GRID_SIZE:
          break

        var total: int
        if cache.hasKey(((x, y), size)):
          total = cache[((x, y), size)]
        else:
          total = grid.getTotalPower((x, y), size)
          cache.add(((x, y), size), total)

        if total > largest:
          largest = total
          result = ((x, y), size)

proc printAnswers(input: int) =
  let grid = initGrid(input)

  echo grid.getLargest3x3()
  echo grid.getLargest()

when isMainModule:
  const input = 2866
  printAnswers(input)
