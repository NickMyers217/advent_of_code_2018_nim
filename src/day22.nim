import strutils, sequtils, sets, tables, heapqueue

type
  ## 2d vector
  Vec = tuple[x, y: int]
  ## The region types
  Region = enum Rocky, Wet, Narrow
  ## Cell data
  Cell = tuple
    geologicalIndex, erosionLevel: int
    region: Region
  ## A grid of cells
  Map = seq[seq[Cell]]
  ## A cave contains its width and depth, the location of the target
  ## and the grid of cells
  Cave = ref object
    width, depth: int
    targetLocation: Vec
    map: Map
  ## The different tools we can equip
  Tool = enum Torch Gear Neither
  ## A move we can make through the cave
  Move = tuple[vec: Vec, tool: Tool]

## Vector math helpers
proc `-`(a, b: Vec): Vec {.inline.} = (x: a.x - b.x, y: a.y - b.y)
proc `+`(a, b: Vec): Vec {.inline.} = (x: a.x + b.x, y: a.y + b.y)
proc up(a: Vec): Vec {.inline.} = a - (0,1)
proc left(a: Vec): Vec {.inline.} = a - (1,0)

proc calcGeologicalIndex(map: Map, vec, target: Vec): int =
  ## Calculate the geologicalIndex for `vec`
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
  ## Calculate the erosionLevel for a given geologicalIndex
  (geologicalIndex + depth) mod 20183

proc calcRegion(erosionLevel: int): Region =
  ## Calculate the region for a given erosionLevel
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

proc newCave(depth: int, targetLocation: Vec, widthPadding: int = 55): Cave =
  ## Construct a new cave
  let width = targetLocation.x + 1 + widthPadding
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
  ## Calculate the total risk level for a cave
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

proc worksInRegion(tool: Tool, region: Region): bool =
  ## Determine if tool will work in the given region
  case region
  of Rocky: return tool in { Gear, Torch }
  of Wet: return tool in { Gear, Neither }
  of Narrow: return tool in { Torch, Neither }

iterator nextMoves(current: Move, cave: Cave): Move =
  ## Iterate all the next possible moves from the current move
  for dir in @[ (0, 1), (1, 0), (0, -1), (-1, 0) ]:
    let (x, y) = current.vec + dir
    if x < 0 or y < 0:
      continue
    let nextCell = cave.map[y][x]
    if current.tool.worksInRegion(nextCell.region):
      yield ((x, y), current.tool)
  for tool in Tool.low .. Tool.high:
    if tool != current.tool and tool.worksInRegion(cave.map[current.vec.y][current.vec.x].region):
      yield (current.vec, tool)

proc findQuickestPath(cave: Cave, start, goal: Move): seq[(Vec, Tool)] =
  ## Use A* to find the quickest path to the target, we didn't really
  ## even need a heuristic function so I didn't use one because I am lazy
  var
    closedSet = initSet[Move]()
    openSet = initSet[Move]()
    cameFrom = initTable[Move, Move]()
    gScore = initTable[Move, int]()
    fScore = initTable[Move, int]()

  openSet.incl(start)
  gScore.add(start, 0)
  fScore.add(start, 0)

  while openSet.len > 0:
    # A heap queue of (fScore, Move) candidates to quickly pick the cheapest move
    var moveQueue = newHeapQueue[(int, Move)]()
    for move in openSet.items:
      moveQueue.push((fScore[move], move))
    var current = moveQueue.pop()[1]

    if current == goal:
      # Reassemble the path
      var path =  @[ current ]
      while cameFrom.hasKey(current):
        current = cameFrom[current]
        path = @[current].concat(path)
      return path[1..^1]

    openSet.excl(current)
    closedSet.incl(current)

    # Process the next moves which are either not moving and switching tools
    # or moving to any adjacent cell that is in bounds and valid for our
    # current tool
    for n in current.nextMoves(cave):
      if n in closedSet:
        continue

      let
        # It costs 7 minutes to switch a tool or 1 to keep the same tool
        timeCost = if n.tool != current.tool: 7 else: 1
        tempGScore = gScore[current] + timeCost

      if n notin openSet: openSet.incl(n)
      elif tempGScore >= gScore[n]: continue

      if cameFrom.hasKeyOrPut(n, current): cameFrom[n] = current
      if gScore.hasKeyOrPut(n, tempGScore): gScore[n] = tempGScore
      if fScore.hasKeyOrPut(n, gScore[n]):
        fScore[n] = gScore[n]

proc totalTime(path: seq[(Vec, Tool)]): int =
  ## Calculate the total time it would take to traverse a path
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
    let path = cave.findQuickestPath(((0, 0), Torch), (cave.targetLocation, Torch))
    echo path.totalTime()

