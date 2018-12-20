import strutils, tables, deques, sets, sequtils

type
  Vec = tuple[x, y: int]
  Edge = enum Wall Door
  Node = tuple
    north, south, east, west: Edge
  Graph = Table[Vec, Node]
  FacilityMap = object
    startPos: Vec
    instructions: string
    graph: Graph
## Vector math helpers
proc `-`(a, b: Vec): Vec {.inline.} = (x: a.x - b.x, y: a.y - b.y)
proc `+`(a, b: Vec): Vec {.inline.} = (x: a.x + b.x, y: a.y + b.y)
proc north(a: Vec): Vec {.inline.} = a - (0,1)
proc south(a: Vec): Vec {.inline.} = a + (0,1)
proc east(a: Vec): Vec {.inline.} = a + (1,0)
proc west(a: Vec): Vec {.inline.} = a - (1,0)
#proc `<`(a, b: Vec): bool {.inline.} = (if a.y == b.y: a.x < b.x else: a.y < b.y)
#proc `*`(a: int, b: Vec): Vec {.inline.} = (x: a * b.x, y: a * b.y)
#proc inc(a: var Vec, b: Vec) {.inline.} = a = a + b
#proc dec(a: var Vec, b: Vec) {.inline.} = a = a - b
iterator neighbors(a: Vec): Vec =
  yield a.north
  yield a.east
  yield a.west
  yield a.south

proc initGraph(instructions: string, startPos: Vec = (0, 0)): Graph =
  result = initTable[Vec, Node]()
  var
    posStack: seq[Vec] = @[]
    curPos = startPos
  for c in instructions:
    echo "Current at ", curPos, " processing ", c, " with stack ", posStack
    case c
    of '^':
      result.add(startPos, (Wall, Wall, Wall, Wall))
    of 'N':
      result[curPos].north = Door
      curPos = curPos.north
      if result.hasKeyOrPut(curPos, (north: Wall, south: Door, east: Wall, west: Wall)):
        result[curPos].south = Door
    of 'S':
      result[curPos].south = Door
      curPos = curPos.south
      if result.hasKeyOrPut(curPos, (north: Door, south: Wall, east: Wall, west: Wall)):
        result[curPos].north = Door
    of 'E':
      result[curPos].east = Door
      curPos = curPos.east
      if result.hasKeyOrPut(curPos, (north: Wall, south: Wall, east: Wall, west: Door)):
        result[curPos].west = Door
    of 'W':
      result[curPos].west = Door
      curPos = curPos.west
      if result.hasKeyOrPut(curPos, (north: Wall, south: Wall, east: Door, west: Wall)):
        result[curPos].east = Door
    of '(':
      posStack.add(curPos)
    of ')':
      curPos = posStack.pop()
    of '|':
      curPos = posStack[^1]
    of '$':
      return result
    else: discard

proc doorBetween(graph: Graph, a, b: Vec): bool =
  result = false
  if graph.hasKey(a) and graph.hasKey(b):
    let delta = b - a
    if delta == (0, -1):
      return graph[a].north == Door and graph[b].south == Door
    if delta == (0, 1):
      return graph[a].south == Door and graph[b].north == Door
    if delta == (1, 0):
      return graph[a].east == Door and graph[b].west == Door
    if delta == (-1, 0):
      return graph[a].west == Door and graph[b].east == Door

proc breadthFirstSearch(graph: Graph, start, goal: Vec): seq[Vec] =
  ## Use breadth first search to find the shortest path between `start` and `goal`
  var
    openSet = initDeque[Vec]()
    closedSet = initSet[Vec]()
    cameFrom = initTable[Vec, Vec]()

  openSet.addLast(start)
  while openSet.len > 0:
    let current = openSet.popFirst()

    if current == goal:
      result = @[goal]
      var temp = current
      while cameFrom.hasKey(temp):
        temp = cameFrom[temp]
        result = @[temp].concat(result)
      return result[1..^1]

    for n in current.neighbors:
      if not graph.hasKey(n) or n in closedSet or (not graph.doorBetween(current, n)):
        continue
      if n notin openSet:
        if cameFrom.hasKeyOrPut(n, current):
          cameFrom[n] = current
        openSet.addLast(n)
    closedSet.incl(current)

proc initFacilityMap(instructions: string, startPos: Vec = (0, 0)): FacilityMap =
  result = FacilityMap(
    startPos: startPos,
    instructions: instructions,
    graph: initGraph(instructions)
  )

proc findFarthestRoom(facility: FacilityMap, n = 1000): (Vec, int, int) =
  ## Test each room in the facility to see how many doors are on the shortest path
  ## to reach that room from the start. Return the location for the room who's path is
  ## the most doors away, as well as the number of doors. Also include a count of the
  ## rooms that were at least `n` doors away from the start.
  ##
  ## This is probably the worst most brute force way to do this, but I think it is
  ## pretty simple and elegant. Maybe i'll look into speeding it up with multi-threading
  result = (facility.startPos, 0, 0)
  var i = 1
  for goalPos in facility.graph.keys:
    echo "Processing room ", i, " out of ", facility.graph.len
    if goalPos != facility.startPos:
      let path = facility.graph.breadthFirstSearch(facility.startPos, goalPos)
      if path.len > result[1]:
        result[0] = goalPos
        result[1] = path.len
      if path.len >= n:
        inc result[2]
    inc i

when isMainModule:
  let
    testInput = "^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$"
    input = readFile("./res/day20.txt").replace("\n", "")
    facility =  initFacilityMap(input)
    (pos, doors, count) = facility.findFarthestRoom

  # Part 1
  echo "Farthest room @ ", pos, " was ", doors, " doors away!"
  # Part 2
  echo "There were ", count, " rooms that were at least 1000 doors away!"
