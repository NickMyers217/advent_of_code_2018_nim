import strutils, sequtils, strscans, tables

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
    offset: Vec = (0, 0)
    xBounds = (0, 0)
    yBounds = (0, 0)
    width = 0
    height = 0

  for point in points:
    let (x, y) = point.position
    if x < xBounds[0]: xBounds[0] = x
    if x > xBounds[1]: xBounds[1] = x
    if y < yBounds[0]: yBounds[0] = y
    if y > yBounds[1]: yBounds[1] = y
  width = xBounds[1] - xBounds[0] + 1
  height = yBounds[1] - yBounds[0] + 1
  offset = (xBounds[0] * -1, yBounds[0] * -1)

  result = (width, height, offset)

func generateLookup*(points: seq[Point]): Table[Vec, int] =
  result = initTable[Vec, int]()
  for i, p in points:
    ## TODO: should probably throw if this was true
    discard result.hasKeyOrPut(p.position, i)

func newGrid*(points: seq[Point]): Grid =
  ## Create a new grid
  let
    (width, height, offset) = mapPointsToSky(points)
    pointsLookup = generateLookup(points)

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
    var isValid = false
    for n in neighbors:
      let vecToCheck = p.position + n
      if grid.pointsLookup.hasKey(vecToCheck):
        isValid = true

    if not isValid:
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
  grid.pointsLookup = generateLookup(grid.points)
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

  ## This thing is large, check the bottom right corner in a tiny font
  echo grid
  echo time

when isMainModule:
  printAnswers("res/day10.txt")
