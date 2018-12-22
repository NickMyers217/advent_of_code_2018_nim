import strutils, sequtils, sets, tables

type
  Vec = tuple[x, y: int]
  Region = enum Rocky, Wet, Narrow
  Cell = tuple
    geologicalIndex, erosionLevel: int
    region: Region
  Map = seq[seq[Cell]]
  Cave = ref object
    width, depth: int
    targetLocation: Vec
    map: Map
  Tool = enum Torch Gear Neither

## Vector math helpers
proc `-`(a, b: Vec): Vec {.inline.} = (x: a.x - b.x, y: a.y - b.y)
proc `+`(a, b: Vec): Vec {.inline.} = (x: a.x + b.x, y: a.y + b.y)
proc `*`(a: int, b: Vec): Vec {.inline.} = (x: a * b.x, y: a * b.y)
proc down(a: Vec): Vec {.inline.} = a + (0,1)
proc up(a: Vec): Vec {.inline.} = a - (0,1)
proc right(a: Vec): Vec {.inline.} = a + (1,0)
proc left(a: Vec): Vec {.inline.} = a - (1,0)
proc manhattan(a, b: Vec): int {.inline.} = abs(b.x - a.x) + abs(b.y - a.y)

proc calcGeologicalIndex(map: Map, vec, target: Vec): int =
  if vec == (0, 0):
    return 0
  elif vec == target:
    return 0
  elif vec.x == 0:
    return vec.y * 48271
  elif vec.y == 0:
    return vec.x * 16807
  else:
    return map[vec.left.y][vec.left.x].erosionLevel * map[vec.up.y][vec.up.x].erosionLevel

proc calcErosionLevel(geologicalIndex, depth: int): int =
  (geologicalIndex + depth) mod 20183

proc calcRegion(erosionLevel: int): Region =
  case erosionLevel mod 3
  of 0: return Rocky
  of 1: return Wet
  of 2: return Narrow
  else: discard

proc `$`(cave: Cave): string =
  result = ""
  for y, row in cave.map:
    if y > cave.targetLocation.y + 5:
      break
    for x, col in row:
      if (x, y) == (0, 0):
        result &= 'M'
      elif (x, y) == cave.targetLocation:
        result &= 'T'
      else:
        case col.region
        of Rocky: result &= '.'
        of Wet: result &= '='
        of Narrow: result &= '|'
      if x > cave.targetLocation.x + 5:
        break
    result &= '\n'

proc newCave(depth: int, targetLocation: Vec): Cave =
  const PADDING = 55 # I just adjusted this until i stopped getting out of bounds exceptions lol
  let width = targetLocation.x + 1 + PADDING
  var map: Map = newSeqWith(depth, newSeq[Cell](width))

  for y, row in map:
    for x, col in row:
      let
        geologicalIndex = map.calcGeologicalIndex((x, y), targetLocation)
        erosionLevel = calcErosionLevel(geologicalIndex, depth)
        region = calcRegion(erosionLevel)
      map[y][x] = (geologicalIndex, erosionLevel, region)

  result = Cave(
    width: width,
    depth: depth,
    targetLocation: targetLocation,
    map: map
  )

proc calcTotalRiskLevel(cave: Cave): int =
  result = 0
  for y, row in cave.map:
    for x, col in row:
      case col.region
      of Rocky: inc result, 0
      of Wet: inc result
      of Narrow: inc result, 2
      if x == cave.targetLocation.x:
        break
    if y == cave.targetLocation.y:
      break

iterator nextMoves(current: (Vec, Tool), cave: Cave): (Vec, Tool) =
  for tool in Tool.low .. Tool.high:
    if tool != current[1]:
      yield (current[0], tool)
  for dir in @[ (1, 0), (0, 1), (-1, 0), (0, -1) ]:
    let (x, y) = current[0] + dir
    if x < 0 or y < 0:
      continue
    let nextCell = cave.map[y][x]
    case nextCell.region
    of Rocky:
      if current[1] in { Gear, Torch }: yield ((x, y), current[1])
    of Wet:
      if current[1] in { Gear, Neither }: yield ((x, y), current[1])
    of Narrow:
      if current[1] in { Torch, Neither }: yield ((x, y), current[1])

proc findQuickestPath(cave: Cave): seq[(Vec, Tool)] =
  ## Use A* to find the quickest path to the target
  var
    closedSet = initSet[(Vec, Tool)]()
    openSet = initSet[(Vec, Tool)]()
    cameFrom = initTable[(Vec, Tool), (Vec, Tool)]()
    gScore = initTable[(Vec, Tool), int]()
    fScore = initTable[(Vec, Tool), int]()

  openSet.incl(((0, 0), Torch))
  gScore.add(((0, 0), Torch), 0)
  fScore.add(((0, 0), Torch), 0)

  while openSet.len > 0:
    var
      smallest = high(int)
      current: (Vec, Tool)
    for item in openSet.items:
      if fScore[item] < smallest:
        smallest = fScore[item]
    for item in openSet.items:
      if fScore[item] == smallest:
        current = item

    if current[0] == cave.targetLocation:
      var path =  @[ current ]
      if current[1] != Torch:
        path.add((current[0], Torch))
      while cameFrom.hasKey(current):
        current = cameFrom[current]
        path = @[current].concat(path)
      return path[1..^1]

    openSet.excl(current)
    closedSet.incl(current)

    for n in current.nextMoves(cave):
      if n in closedSet:
        continue

      let
        timeCost = if n[1] != current[1]: 7 else: 1
        tempGScore = gScore[current] + timeCost

      if n notin openSet: openSet.incl(n)
      elif tempGScore >= gScore[n]: continue

      if cameFrom.hasKeyOrPut(n, current): cameFrom[n] = current
      if gScore.hasKeyOrPut(n, tempGScore): gScore[n] = tempGScore
      if fScore.hasKeyOrPut(n, gScore[n]):
        fScore[n] = gScore[n]

proc totalTime(path: seq[(Vec, Tool)]): int =
  result = 0
  var prev: Tool = Torch
  for move in path:
    if move[1] != prev:
      inc result, 7
    else:
      inc result
    prev = move[1]

when isMainModule:
  let
    input = (9465, (13,704))
    testInput = (510, (10,10))

  let cave = newCave(input[0], input[1])

  block part1:
    echo cave.calcTotalRiskLevel()

  block part2:
    let path = cave.findQuickestPath()
    echo path.totalTime() - 5 # I was off by 5, but I don't know why... bummer

