import lists, strutils, sequtils, algorithm, sets

type
  Point = tuple[x, y: int]
  Turn = enum LeftTurn, NoTurn, RightTurn
  Direction = enum Up, Down, Left, Right
  Cart = ref object
    location: Point
    direction: Direction
    turns: DoublyLinkedRing[Turn]
  Carts = seq[Cart]
  Tracks = seq[string]

proc getTurnRing(): DoublyLinkedRing[Turn] =
  result = initDoublyLinkedRing[Turn]()
  result.append(LeftTurn)
  result.append(NoTurn)
  result.append(RightTurn)

proc newCart(location: Point, direction: Direction): Cart =
  result = Cart(
    location: location,
    direction: direction,
    turns: getTurnRing()
  )

proc cmp(a, b: Cart): int =
  if a.location.y < b.location.y: result = -1
  if a.location.y == b.location.y: result = cmp(a.location.x, b.location.x)
  else: result = 1

proc parseInput(input: string): (Tracks, Carts) =
  result = (input.splitLines().filterIt(it != ""), @[])
  for y, row in result[0]:
    for x, c in row:
      case c
      of '^':
        result[0][y][x] = '|'
        result[1].add newCart((x, y), Up)
      of 'v':
        result[0][y][x] = '|'
        result[1].add newCart((x, y), Down)
      of '<':
        result[0][y][x] = '-'
        result[1].add newCart((x, y), Left)
      of '>':
        result[0][y][x] = '-'
        result[1].add newCart((x, y), Right)
      else: continue

proc tick(cart: var Cart, tracks: Tracks): void =
  proc turnLeft(dir: Direction): Direction {.closure.} =
    case dir
    of Up: Left
    of Left: Down
    of Down: Right
    of Right: Up

  proc turnRight(dir: Direction): Direction {.closure.} =
    case dir
    of Up: Right
    of Right: Down
    of Down: Left
    of Left: Up

  let (x, y) = cart.location
  case tracks[y][x]
  of '/':
    cart.direction =
      case cart.direction
      of Up, Down: turnRight(cart.direction)
      of Left, Right: turnLeft(cart.direction)
  of '\\':
    cart.direction =
      case cart.direction
      of Up, Down: turnLeft(cart.direction)
      of Left, Right: turnRight(cart.direction)
  of '+':
    cart.direction =
      case cart.turns.head.value
      of LeftTurn: turnLeft(cart.direction)
      of NoTurn: cart.direction
      of RightTurn: turnRight(cart.direction)
    cart.turns.head = cart.turns.head.next
  else: discard

  case cart.direction
  of Up: dec cart.location.y
  of Down: inc cart.location.y
  of Left: dec cart.location.x
  of Right: inc cart.location.x

when isMainModule:
  let input = readFile("res/day13.txt")

  ### Part 1
  block part1:
    var (tracks, carts) = parseInput(input)
    while true:
      carts = carts.sorted(cmp)
      for i in carts.low .. carts.high:
        tick(carts[i], tracks)

        var crashed = false
        for j in 0..carts.high:
          if j != i and carts[i].location == carts[j].location:
            crashed = true
            break
        if crashed:
          echo carts[i].location.x, ",", carts[i].location.y
          break part1

  ### Part 2
  block part2:
    var (tracks, carts) = parseInput(input)

    while carts.len > 1:
      carts = carts.sorted(cmp)

      var indicesToRemove = initSet[int]()
      for i in carts.low .. carts.high:
        carts[i].tick(tracks)

        for j in carts.low .. carts.high:
          if j != i and carts[i].location == carts[j].location:
            indicesToRemove.incl(i)
            indicesToRemove.incl(j)
            echo "Collision @ ", carts[i].location
            break

      var newCarts = newSeq[Cart]()
      for i, cart in carts:
        if i notin indicesToRemove: newCarts.add(cart)
      carts = newCarts

    echo carts[0].location.x, ",", carts[0].location.y

