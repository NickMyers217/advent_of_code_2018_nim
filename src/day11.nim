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

## A silly global cache to help speed things up
var powerCache = initTable[(Point, int), int]()
proc getTotalPower*(grid: Grid, corner: Point, size: int = 1): int =
  ## Gets the total power for a section of size starting at corner
  ## returns 0 if there is not enough space for a full 3x3 section
  if size == 1:
    return grid.getPower(corner)
  if powerCache.hasKey((corner, size)):
    return powerCache[(corner, size)]

  var total = grid.getTotalPower(corner, size - 1)
  for yOff in 0 ..< size:
    if yOff == size - 1:
      for xOff in 0 ..< size:
        total += grid.getPower((corner.x + xOff, corner.y + yOff))
    else:
      total += grid.getPower((corner.x + (size - 1), corner.y + yOff))

  powerCache[(corner, size)]=total
  result = total

proc getLargest*(
  grid: Grid,
  minSize: int = 1,
  maxSize: int = GRID_SIZE
): (Point, int) =
  ## Gets the corner point of any section with the largest total power
  ## also return the size of the section
  var largest = 0
  for y in 1 .. GRID_SIZE:
    for x in 1 .. GRID_SIZE:
      for size in minSize .. maxSize:
        if x + (size - 1) > GRID_SIZE or y + (size - 1) > GRID_SIZE:
          break
        let total = grid.getTotalPower((x, y), size)
        if total > largest:
          largest = total
          result = ((x, y), size)

proc printAnswers(input: int) =
  let
    grid = initGrid(input)
    (point1, size1) = grid.getLargest(3, 3)
    (point2, size2) = grid.getLargest()

  echo point1.x, ",", point1.y
  echo point2.x, ",", point2.y, ",", size2

when isMainModule:
  const input = 2866
  printAnswers(input)
