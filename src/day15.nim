import algorithm, heapqueue, tables, strutils, sequtils, sets

type
  ## A 2d vector for points and directions
  Vec = tuple[y, x: int]
  ## A team for an `Entity`
  Team = enum Elf, Goblin
  ## A game entity
  Entity = ref object
    pos: Vec ## Position on the grid
    hp, ap: int ## Health and attack power
    team: Team ## Their team Cell types
  Cell = enum Open, Wall, Combatant
  ## A game
  Game* = ref object
    grid*: seq[seq[Cell]] ## A 2d grid of `Cell`s
    entities*: Table[Vec, Entity] ## A lookup of `Entity` by position
    round*: int ## The current round
    teamCounts*: tuple[elves, goblins: int] ## The amount of remaining entities

proc `+`(a, b: Vec): Vec =
  ## Vector addition
  result = (y: a.y + b.y, x: a.x + b.x)

proc `-`(a, b: Vec): Vec =
  ## Vector subtraction
  result = (y: a.y - b.y, x: a.x - b.x)

proc manhattan(a, b: Vec): int =
  ## Manhattan distance between 2 vecs
  result = abs(a.y - b.y) + abs(a.x - b.x)

proc newEntity(pos: Vec, team: Team): Entity =
  ## Construct a new `Entity`
  result = Entity(pos: pos, hp: 200, ap: 3, team: team)

iterator neighbors(vec: Vec, game: Game): Vec =
  ## Iterate a location `Vec` for each cell that neighbors `vec` on `game`'s grid
  ## make sure to do it in reading-order
  let neighbors: seq[Vec] = @[ (y: -1, x: 0), (y: 0, x: -1), (y: 0, x: 1), (y: 1, x: 0) ]
  for dir in neighbors:
    yield vec + dir

proc newGame*(input: string): Game =
  ## Construct a new `Game` by parsing it from a string
  let lines = input.splitLines().filterIt(it != "")
  var
    grid = newSeqWith(lines.len, newSeq[Cell](lines[0].len))
    entities = initTable[Vec, Entity]()
    teamCounts = (elves: 0, goblins: 0)
  for y, line in lines:
    for x, cell in line:
      case cell
      of '#': grid[y][x] = Wall
      of '.': grid[y][x] = Open
      of 'E':
        grid[y][x] = Combatant
        entities.add (y, x), newEntity((y, x), Elf)
        inc teamCounts.elves
      of 'G':
        grid[y][x] = Combatant
        entities.add (y, x), newEntity((y, x), Goblin)
        inc teamCounts.goblins
      else: discard

  result = Game(grid: grid, entities: entities, round: 0, teamCounts: teamCounts)

proc `$`*(entity: Entity): string =
  result = case entity.team
  of Elf: "E"
  of Goblin: "G"

proc `$`*(game: Game): string =
  result = ""
  for y, row in game.grid:
    for x, cell in row:
      case cell
      of Wall: result &= '#'
      of Open: result &= '.'
      of Combatant: result &= $game.entities[(y, x)]
    result &= '\n'

proc renderWithHpInfo*(game: Game): string =
  ## Take a game, convert it to a string, and add hp info to it
  var lines = ($game).splitLines().filterIt(it != "")
  for y, row in game.grid:
    var hpStrings: seq[string] = @[]
    for x, cell in row:
      case cell
      of Combatant:
        let entity = game.entities[(y,x)]
        hpStrings.add($entity & "(" & $entity.hp & ")")
      else: discard
    let hpInfo = hpStrings.join(", ")
    lines[y] &= "   " & hpInfo
  result = lines.join("\n")

proc newPosHeap(entities: Table[Vec, Entity]): HeapQueue[Vec] =
  ## Make a new heap queue out of an entities table
  result = newHeapQueue[Vec]()
  for pos in entities.keys:
    result.push pos

proc pathFind(game: Game, start, goal: Vec, debug: bool = false): seq[Vec] =
  ## An implementation of the A* algorithm for efficient pathfinding
  ## Returns the shortest best reading-order seq of locations that need
  ## to be visited to get from `start` to `goal`, or an empty seq
  ## if `goal` cannot be reached
  var
    closedSet = initSet[Vec]() # The cells we have checked already
    openSet = initSet[Vec]() # The cells we have discovered for checking
    cameFrom = initTable[Vec, Vec]() # A lookup to find the previous location of a cell
    gScore = initTable[Vec, int]() # A lookup for a cell's gScore (the # of steps taken)
    fScore = initTable[Vec, int]() # A lookup for a cell's fScore (see the heuristic)

  proc heuristic(a, b: Vec): int {.closure.}  =
    ## A heuristic to determine the fScore of a and b
    ## the fScore should be an estimate of best-case  distance left to the goal
    ##
    ## NOTE: It is super important that you catch this edge case:
    ##
    ##  Moving the goblin on (1, 4) to (5, 5)
    ##  #######
    ##  #..G..# <-- need to path find for (1, 3)
    ##  #...G.# <-- need to path find for (2, 4)
    ##  #.#G#G#
    ##  #...#E#
    ##  #.....# <-- trying to get here (y: 5, x: 5)
    ##  #######
    ##
    ## If you just take the manhattan distance from (1, 3) to (5, 5)
    ## and compare it to the manhattan of (2, 4) and (5, 5) you will
    ## see that (2, 4) has a lower score; even though they are actually
    ## the same number of steps from (5, 5) AND (1, 3) is first in reading
    ## order. We really needed to take just the manhattan from (1, 4)
    ## for both, so that the fScore could tie and be resolved by the heap
    ## queue later on.
    result =
      if cameFrom.hasKey(a): manhattan(cameFrom[a], b)
      else: manhattan(a, b)

  openSet.incl(start)
  gscore.add(start, 0)
  fscore.add(start, heuristic(start, goal))

  while openSet.len > 0:
    # This queue will always pop the vec with the best reading order first
    var nextQueue = newHeapQueue[Vec]()
    for vec in openSet.items:
      if nextQueue.len == 0 or fScore[vec] <= fScore[nextQueue[0]]:
        # Push on the lowest fScores we find, since they are our best shot
        nextQueue.push(vec)
    if debug:
      debugEcho "===>Nearest Queue:"
      for i in 0 ..< nextQueue.len:
        debugEcho "====>", nextQueue[i]
    # The first item in the queue will be the lowest fScore, and the best reading-order
    var current = nextQueue.pop()

    # We made it, so build up the seq of steps to return
    if current == goal:
      result = @[current]
      while cameFrom.hasKey(current):
        current = cameFrom[current]
        result = @[current].concat(result)
      return result[1 .. result.high] # Exclude the start point from the steps

    # Move this cell from the openSet to the closedSet since we are processing it now
    openSet.excl(current)
    closedSet.incl(current)

    for neighbor in current.neighbors(game):
      let (y, x) = neighbor
      if game.grid[y][x] != Open or closedSet.contains(neighbor):
        # Don't check this cell, it is a waste of effort
        continue

      let tempGScore = gScore[current] + 1

      if neighbor notin openSet:
        openSet.incl(neighbor) # We just discovered a new cell
      elif tempGScore >= gScore[neighbor]:
        # This neighbor was discovered earlier and had a better gScore
        # so lets continue for now and come back to this laster
        continue

      # Update the lookups
      if cameFrom.hasKeyOrPut(neighbor, current):
        cameFrom[neighbor] = current
      if gScore.hasKeyOrPut(neighbor, tempGScore):
        gScore[neighbor] = tempGScore
      if fScore.hasKeyOrPut(neighbor, gScore[neighbor] + heuristic(neighbor, goal)):
        fScore[neighbor] = gScore[neighbor] + heuristic(neighbor, goal)

proc getNextMove(game: Game, entity: Entity, debug: bool = false): Vec =
  ## Get a direction vec for the next move that `entity` should make on the grid
  # 1) find all of the potential points we can move to
  var destinations: seq[Vec] = @[]
  for candidate in game.entities.values:
    if candidate.pos == entity.pos or candidate.team == entity.team:
      continue
    for pos in candidate.pos.neighbors(game):
      let (y, x) = pos
      if game.grid[y][x] == Open:
        destinations.add(pos)

  if debug: debugEcho "==>Destinations: ", destinations

  # Nowhere to go, the move is (0, 0)
  if destinations.len == 0:
    return (0, 0)

  # 2) Do pathfinding to find which of the desitinations are reachable
  var
    paths = initTable[Vec, seq[Vec]]()
    reachable: seq[Vec] = @[]

  for vec in destinations:
    let path = game.pathFind(entity.pos, vec, false)
    if path.len > 0:
      paths.add(vec, path)
      reachable.add(vec)
      if debug: debugEcho "==>Reachable: ", vec, " => ", path

  # Nothing as reachable, the move is (0, 0)
  if reachable.len ==  0:
    return (0, 0)

  # 3) Find the reachable points with the smallest distance
  var
    smallestLen: int
    nearest = newHeapQueue[Vec]() # This heap queue will handle ties
  for vec in reachable:
    if smallestLen == 0 or paths[vec].len <= smallestLen:
      smallestLen = paths[vec].len
  for vec in reachable:
    if paths[vec].len == smallestLen:
      nearest.push(vec)
  if debug: debugEcho "==>Nearest: ", nearest[0]

  # 4) Choose the smalest reachable point with the best reading-order,
  # take the direction of the first move on the path there
  result = paths[nearest.pop()][0] - entity.pos

proc move(game: var Game, entity: var Entity, delta: Vec): void =
  ## Move `entity` by the `delta` vec, and update `game` accordingly
  if delta == (0,0): return
  let dest = entity.pos + delta
  assert game.grid[dest.y][dest.x] == Open
  game.grid[entity.pos.y][entity.pos.x] = Open
  game.grid[dest.y][dest.x] = Combatant
  game.entities.del(entity.pos)
  entity.pos = dest
  assert (not game.entities.hasKey(dest))
  game.entities.add(dest, entity)

proc getNeighboringTarget(game: Game, entity: Entity): Entity =
  ## Return the lowest HP and best reading-order Entity that `entity` can
  ## currently attack on the game grid, or nill if there isn't one
  result = nil
  for pos in entity.pos.neighbors(game):
    if game.entities.hasKey(pos):
      var target = game.entities[pos]
      if target.team != entity.team and (result == nil or target.hp < result.hp):
        result = target

proc attack(game: var Game, entity, target: var Entity): void =
  ## Have `entity` attck `target` and update `game` accordingly
  target.hp -= entity.ap

  if target.hp <= 0:
    game.grid[target.pos.y][target.pos.x] = Open
    case target.team
    of Elf: dec game.teamCounts.elves
    of Goblin: dec game.teamCounts.goblins
    game.entities.del(target.pos)

proc advanceRound*(game: var Game, debug: bool = false): void =
  ## Advance the state of `game` forward by one round

  # Queue up the entities by reading-order
  var
    elvesWhoAttacked = 0
    goblinsWhoAttacked = 0
    posQueue = newPosHeap(game.entities)

  inc game.round

  while posQueue.len > 0:
    let nextPos = posQueue.pop()

    if not (game.entities.hasKey(nextPos)):
      # This entity was killed earlier in the round
      continue

    var
      entity = game.entities[nextPos]
      target = game.getNeighboringTarget(entity) # Check for a target

    if debug:
      debugEcho "ROUND: ", game.round
      debugEcho "[Start] ", entity, entity.pos

    if target != nil:
      # We are in range to attack
      game.attack(entity, target)
      if entity.team == Elf: inc elvesWhoAttacked
      if entity.team == Goblin: inc goblinsWhoAttacked
      if debug: debugEcho "=>Attack first: ", target.pos
    else:
      var combatEnded = true
      for e in game.entities.values:
        if e.team != entity.team:
          combatEnded = false
      if combatEnded:
        if debug: debugEcho "***** COMBAT ENDED *****"
        dec game.round
        break

      # Try to move
      let delta = game.getNextMove(entity, false)
      if debug: debugEcho "=>Moving ", delta
      game.move(entity, delta)

      # Try and attack again after our move
      target = game.getNeighboringTarget(entity)
      if target != nil:
        game.attack(entity, target)
        if entity.team == Elf: inc elvesWhoAttacked
        if entity.team == Goblin: inc goblinsWhoAttacked
        if debug: debugEcho "=>Attack after move!"

    if debug:
      debugEcho "[End]"
      debugEcho "------------------------------------"

  if debug:
    debugEcho "\n"
    debugEcho "AFTER ROUND: ", game.round
    debugEcho game.renderWithHpInfo()
    debugEcho "\n"
    debugEcho "************************************"
    debugEcho "\n"

proc play*(game: var Game, debug: bool = false): void =
  ## Advances the state of `game` until one of the teams wins
  while game.teamCounts.elves != 0 and game.teamCounts.goblins != 0:
    game.advanceRound(debug)

proc tallyScore*(game: Game): int =
  ## Calcuate the product of the full rounds played and
  ## the sum of the remaining units' hp
  var hpSum = 0
  for entity in game.entities.values:
    hpSum += entity.hp
  result = game.round * hpSum

when isMainModule:
  let input = readFile("res/day15.txt")
  var game = newGame(input)
  game.play(true)
  echo game.tallyScore
