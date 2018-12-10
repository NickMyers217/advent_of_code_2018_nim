import strutils, sequtils, strscans, tables, algorithm

type
  ## A 2d vector
  Vec* = tuple[x, y: int]

  ## A position and a velocity
  Point* = tuple[position, velocity: Vec]

  ## A 2d grid of points
  ## it stores a seq of points, but to speed up accessing them
  ## we also have a lookup to find their index via their position
  Grid* = ref object
    width*, height*: int
    offset*: Vec # accounts for shifting the origin to (0, 0)
    pointsLookup: Table[Vec, int]
    points*: seq[Point]
    messageFound*: bool

func initVec*(input: string): Vec =
  ## Parse a Vec from puzzle input
  var x, y: int
  if input.replace(" ", "").scanf("$i,$i", x, y):
    result = (x: x, y: y)

func `+`*(a, b: Vec): Vec =
  ## Vector addition
  result = (x: a.x + b.x, y: a.y + b.y)

func `*`*(scalar: int, a: Vec): Vec =
  ## Scalar multiplication
  result = (x: a.x * scalar, y: a.y * scalar)

func initPoint*(posString, velString: string): Point =
  ## Init a point from a line of the puzzle input
  result = (position: initVec(posString), velocity: initVec(velString))

func initPoint*(input: string): Point =
  ## Init a point from a line of the puzzle input
  var posString, velString: string
  if input.scanf("position=<$+> velocity=<$+>", posString, velString):
    result = initPoint(posString, velString)

proc mapPointsToSky*(points: seq[Point]): (int, int, Vec) =
  ## Take a list of points and map them onto a 2d grid
  ## return the width and height
  ## also return an offset vec used to make the origin 0, 0

  # Determine the width and height of the grid
  var
    sortedX = points
      .map(proc(p: Point): int = p.position.x)
      .sorted(cmp[int])
    sortedY = points
      .map(proc(p: Point): int = p.position.y)
      .sorted(cmp[int])
    xBounds, yBounds, offset: Vec
    width, height: int

  xBounds[0] = sortedX[0]
  xBounds[1] = sortedX[sortedX.high]
  yBounds[0] = sortedY[0]
  yBounds[1] = sortedY[sortedY.high]

  width = xBounds[1] - xBounds[0] + 1
  height = yBounds[1] - yBounds[0] + 1
  offset = (xBounds[0] * -1, yBounds[0] * -1)

  result = (width, height, offset)

func generateLookup*(points: seq[Point], offset: Vec): Table[Vec, int] =
  result = initTable[Vec, int]()
  for i, p in points:
    ## TODO: should probably throw if this was true
    discard result.hasKeyOrPut(p.position + offset, i)

func newGrid*(points: seq[Point]): Grid =
  ## Create a new grid
  let
    (width, height, offset) = mapPointsToSky(points)
    pointsLookup = generateLookup(points, offset)

  result = Grid(
    width: width,
    height: height,
    offset: offset,
    pointsLookup: pointsLookup,
    points: points,
    messageFound: false
  )

func `$`*(grid: Grid): string =
  ## Visualize a grid's night sky as a string
  result = ""
  for y in 0 ..< grid.height:
    var row = ""
    for x in 0 ..< grid.width:
      if grid.pointsLookup.hasKey((x, y)): row &= "#"
      else: row &= '.'
    result &= row & "\n"

func checkForMessage*(grid: Grid): bool =
  ## Returns true if there is a message on the grid
  ## that is determined by ensuring every point is
  ## neighboring another
  result = true

  const neighbors: seq[Vec] = @[
    (-1, 0), (1, 0), (0, -1), (0, 1),
    (-1, -1), (1, -1), (-1, 1), (1, 1)
  ]

  for p in grid.points:
    block checkPoint:
      for n in neighbors:
        let vecToCheck = p.position + n
        if grid.pointsLookup.hasKey(vecToCheck + grid.offset):
          break checkPoint
      return false

proc advance*(point: var Point, n: int = 1) =
  ## Advance a point by n seconds
  point.position = point.position + (n * point.velocity)

proc advance*(grid: var Grid, n: int = 1) =
  ## Advance an entire grid by n seconds

  # Calculate the new point positions
  for i in 0 ..< grid.points.len:
    grid.points[i].advance(n)

  # Update the grid accordingly
  let (width, height, offset) = mapPointsToSky(grid.points)
  grid.pointsLookup = generateLookup(grid.points, offset)
  grid.width = width
  grid.height = height
  grid.offset = offset

  # Check the grid for a message
  grid.messageFound = grid.checkForMessage()

proc printAnswers(filePath: string) =
  let points = filePath
    .readFile()
    .splitLines()
    .filterIt(it != "")
    .map(initPoint)
  var grid = newGrid(points)

  var time = 10700
  grid.advance(time)
  while not grid.messageFound:
    grid.advance()
    inc time

  # Check this with a TINY font
  echo grid
  echo time

when isMainModule:
  printAnswers("res/day10.txt")
