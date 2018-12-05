import strutils, sequtils

type
  ## Represents an x,y coordinate on a grid
  Point = tuple[x: int, y: int]

  ## Defines a rectangle of fabric
  Rect* = object
    id*: int
    x*, y*: int
    width*, height*: int

  ## Defines a grid of `width` * `height` points
  ## `values` is the amount of times each point has been marked
  Grid* = ref object
    width*, height*: int
    values*: seq[int]


proc initRect*(input: string): Rect =
  ## Initialise a Rect from its string representation
  let elements = input
    .split({ ' ', '#', '@', ',', ':', 'x' })
    .filter(proc(e: string): bool = e != "")
    .map(parseInt)

  assert elements.len() == 5

  Rect(id: elements[0], x: elements[1], y: elements[2], width: elements[3], height: elements[4])

proc `$`*(rect: Rect): string =
  ## Render a Rect as a string
  "#$1 @ $2,$3: $4x$5" % [$rect.id, $rect.x, $rect.y, $rect.width, $rect.height]

iterator points*(r: Rect): Point =
  ## Iterates over each x,y point within a given rectangle
  for y in r.y .. r.y + r.height - 1:
    for x in r.x .. r.x + r.width - 1:
      yield (x, y)


proc newGrid*(width, height: int): Grid =
  ## Creates a new grid
  Grid(width: width, height: height, values: newSeq[int](width * height))

proc mark*(grid: var Grid, point: Point): void =
  ## Ups the count in `grid`'s values array at index for `point`
  let i = point.y * grid.width + point.x

  ## We cannot mark a point that is not specified by this grid
  assert i >= 0 and i < grid.values.len()

  grid.values[i] += 1

proc mark*(grid: var Grid, rect: Rect): void =
  ## Marks `grid` with all the points defined by `rect`
  for point in rect.points():
    grid.mark(point)

proc doesNotOverlap*(grid: Grid, rect: Rect): bool =
  ## Verifies all of the points specified by `rect` have a count equal to 1 on `grid`
  result = true
  for point in rect.points():
    let i = point.y * grid.width + point.x
    ## We cannot get a point that is not specified by this grid
    assert i >= 0 and i < grid.values.len()

    if grid.values[i] != 1:
      return false


proc printAnswers*(filePath: string): void =
  ## Get the answer for the first part
  var grid = newGrid(1000, 1000)
  let rects = filePath
    .readFile()
    .splitLines()
    .filter(proc(e: string): bool = e != "")
    .map(initRect)

  for rect in rects:
    grid.mark(rect)

  echo grid.values.filter(proc(count: int): bool = count >= 2).len()

  let nonOverlaps = rects.filter(proc(e: Rect): bool = grid.doesNotOverlap(e))

  assert nonOverlaps.len() == 1
  echo nonOverlaps[0].id


when isMainModule:
  printAnswers("res/day3.txt")
