import strutils, sequtils, tables, sets, algorithm

type
  Point* = tuple[x, y: int]

  Move* = enum left, straight, right

  Cart* = ref object
    location*: Point
    symbol*: char
    nextMove*: Move
    removed*: bool

proc newCart*(point: Point, symbol: char): Cart =
  result = Cart(location: point, symbol: symbol, nextMove: left, removed: false)

proc `$`*(cart: Cart): string =
  result = "$1 @ $2" % [ $cart.symbol, $cart.location ]

proc tick*(cart: var Cart, tracks: seq[string]) =
  proc turnLeft(cart: Cart): char {.closure.} =
    if cart.symbol == '>': return '^'
    if cart.symbol == '^': return '<'
    if cart.symbol == '<': return 'v'
    if cart.symbol == 'v': return '>'

  proc turnRight(cart: Cart): char {.closure.} =
    if cart.symbol == '>': return 'v'
    if cart.symbol == 'v': return '<'
    if cart.symbol == '<': return '^'
    if cart.symbol == '^': return '>'

  if cart.symbol == '>': cart.location.x += 1
  elif cart.symbol == '<': cart.location.x -= 1
  elif cart.symbol == 'v': cart.location.y += 1
  elif cart.symbol ==  '^': cart.location.y -= 1

  let
    cell = tracks[cart.location.y][cart.location.x]
    isHorizontal = cart.symbol in { '<', '>' }

  if cell == '/':
    if isHorizontal: cart.symbol = cart.turnLeft()
    else: cart.symbol = cart.turnRight()
  elif cell == '\\':
    if isHorizontal: cart.symbol = cart.turnRight()
    else: cart.symbol = cart.turnLeft()
  elif cell == '+':
    case cart.nextMove
    of left:
      cart.symbol = cart.turnLeft()
      cart.nextMove = straight
    of straight:
      cart.nextMove = right
    of right:
      cart.symbol = cart.turnRight()
      cart.nextMove = left

proc parseInput*(input: string): (seq[string], seq[Cart]) =
  result = (input.splitLines().filterIt(it != ""), @[])
  for y, row in result[0]:
    for x, c in row:
      if c in { '^', 'v', '>', '<' }:
        result[1].add(newCart((x, y), c))

proc findFirstCollision*(tracks: seq[string], carts: seq[Cart]): Point =
  var
    cartsCopy = carts
    collision = false
  while true:
    for i in cartsCopy.low .. cartsCopy.high:
      cartsCopy[i].tick(tracks)
    var seen = initSet[Point]()
    for cart in cartsCopy:
      if seen.contains(cart.location):
        return cart.location
      else:
        seen.incl(cart.location)


when isMainModule:
  let input = readFile("res/day13.txt")

  var (tracks, carts) = parseInput(input)

  ### Part 1
  var part1Point = findFirstCollision(tracks, carts)
  echo part1Point.x, ",", part1Point.y

  ### Part 2
  var t = 0
  while carts.filterIt(not it.removed).len > 1:
    var seen = initSet[Point]()

    carts = carts
    .filterIt(not it.removed)
    .sorted(proc(a, b: Cart): int =
      if $a.location.y < $b.location.y:
        return -1
      elif $a.location.y == $b.location.y:
        if $a.location.x < $b.location.x: return -1
        elif $a.location.x == $b.location.x: return 0
        else: return 1
      else: return 1
    )

    for i in carts.low .. carts.high:
      if carts[i].removed:
        continue
      carts[i].tick(tracks)
      if seen.contains(carts[i].location):
        echo "Collision @ ", $carts[i].location.x, ",", $carts[i].location.y, " on tick ", $t
        for j in carts.low .. carts.high:
          if carts[j].location == carts[i].location:
            carts[j].removed = true
      else:
        seen.incl(carts[i].location)

    inc t

  echo carts[0].location.x, ",", carts[0].location.y
