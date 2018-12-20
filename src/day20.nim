import strutils, tables, deques, sets, sequtils

type
  ## 2d vectors (really tired of making this type every day lol)
  Vec = tuple[x, y: int]
  ## The types of edges on a graph
  Edge = enum Wall Door
  ## A node on a graph is just 4 edges
  Node = tuple
    north, south, east, west: Edge
  ## A graph is just a lookup of nodes by their coordinates (relative to the origin)
  Graph = Table[Vec, Node]
  ## A facility is a start position, a set of instructions to generate a graph, and the graph
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
iterator neighbors(a: Vec): Vec =
  ## iterate the neighbors lazy man style
  yield a.north
  yield a.east
  yield a.west
  yield a.south

proc initGraph(instructions: string, startPos: Vec = (0, 0)): Graph =
  ## Generate a graph from a set of instructions using an explicit stack to iterate the different branches
  result = initTable[Vec, Node]()
  var
    posStack: seq[Vec] = @[] # The locations we branched
    curPos = startPos # Our current location
  for c in instructions:
    echo "Current at ", curPos, " processing ", c, " with stack ", posStack
    case c
    of '^':
      # the start
      result.add(startPos, (Wall, Wall, Wall, Wall))
    of 'N':
      # Make sure there is a node north with the proper edges
      result[curPos].north = Door
      curPos = curPos.north
      if result.hasKeyOrPut(curPos, (north: Wall, south: Door, east: Wall, west: Wall)):
        result[curPos].south = Door
    of 'S':
      # Make sure there is a node south with the proper edges
      result[curPos].south = Door
      curPos = curPos.south
      if result.hasKeyOrPut(curPos, (north: Door, south: Wall, east: Wall, west: Wall)):
        result[curPos].north = Door
    of 'E':
      # Make sure there is a node east with the proper edges
      result[curPos].east = Door
      curPos = curPos.east
      if result.hasKeyOrPut(curPos, (north: Wall, south: Wall, east: Wall, west: Door)):
        result[curPos].west = Door
    of 'W':
      # Make sure there is a node west with the proper edges
      result[curPos].west = Door
      curPos = curPos.west
      if result.hasKeyOrPut(curPos, (north: Wall, south: Wall, east: Door, west: Wall)):
        result[curPos].east = Door
    of '(':
      # We branched, add a new location to the stack
      posStack.add(curPos)
    of '|':
      # Reset to the start of this branch to test the next possibility
      curPos = posStack[^1]
    of ')':
      # This branch is over, pop back
      curPos = posStack.pop()
    of '$':
      # The end
      return result
    else: discard

proc doorBetween(graph: Graph, a, b: Vec): bool =
  ## Return true if there are door edges between adjacent nodes `a` and `b` on `graph`
  ## otherwise return false
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
      # We found the path, reconstruct it
      result = @[goal]
      var temp = current
      while cameFrom.hasKey(temp):
        temp = cameFrom[temp]
        result = @[temp].concat(result)
      return result[1..^1] # Don't include the start node's positin

    for n in current.neighbors:
      if not graph.hasKey(n) or n in closedSet or (not graph.doorBetween(current, n)):
        continue
      if n notin openSet:
        if cameFrom.hasKeyOrPut(n, current):
          cameFrom[n] = current
        openSet.addLast(n)
    closedSet.incl(current)

proc initFacilityMap(instructions: string, startPos: Vec = (0, 0)): FacilityMap =
  ## Construct a FacilityMap
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
