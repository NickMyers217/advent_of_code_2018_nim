import lists, strutils, sequtils, algorithm, sets

type
  ## An x,y coordinate (origin is top left)
  Point* = tuple[x, y: int]
  ## A cart can turn left, go straight, or turn right
  Turn = enum LeftTurn, NoTurn, RightTurn
  ## Directions a cart can travel
  Direction = enum Up, Down, Left, Right
  ## A carts location, direction, and a turns ring where the head is the next turn
  Cart = ref object
    location: Point
    direction: Direction
    turns: SinglyLinkedRing[Turn]
  ## Helpful aliases
  Carts = seq[Cart]
  Tracks = seq[string]

proc getTurnRing(): SinglyLinkedRing[Turn] =
  ## Constructs the turn ring for a `Cart`
  result = initSinglyLinkedRing[Turn]()
  result.append(LeftTurn)
  result.append(NoTurn)
  result.append(RightTurn)

proc newCart(location: Point, direction: Direction): Cart =
  ## Constructs a new `Cart`
  result = Cart(
    location: location,
    direction: direction,
    turns: getTurnRing()
  )

proc cmp(a, b: Cart): int =
  ## Determine which `Cart` is closest to the origin
  if a.location.y < b.location.y: result = -1
  if a.location.y == b.location.y: result = cmp(a.location.x, b.location.x)
  else: result = 1

proc parseInput(input: string): (Tracks, Carts) =
  ## Parse the puzzle input into `Tracks` and `Carts`
  result = (input.splitLines().filterIt(it != ""), @[])
  for y, row in result[0]:
    for x, c in row:
      # Take care to insert the character that would be under the cart
      # back into the string in the cart's place
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
  ## Advance `cart` to its next state on the `tracks`
  proc turnLeft(dir: Direction): Direction {.closure.} =
    ## Helper to calculate a new direction after a left turn
    case dir
    of Up: Left
    of Left: Down
    of Down: Right
    of Right: Up

  proc turnRight(dir: Direction): Direction {.closure.} =
    ## Helper to calculate a new direction after a right turn
    case dir
    of Up: Right
    of Right: Down
    of Down: Left
    of Left: Up

  # Handle any potential directional changes
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
    # Advance the head of the turn ring
    cart.turns.head = cart.turns.head.next
  else: discard

  # Move the cart in its new direction
  case cart.direction
  of Up: dec cart.location.y
  of Down: inc cart.location.y
  of Left: dec cart.location.x
  of Right: inc cart.location.x

proc findFirstCollision*(input: string): Point =
  ## Finds the location of the first collision on the tracks
  var (tracks, carts) = parseInput(input)

  while true:
    carts = carts.sorted(cmp) # Always keep these sorted

    for i in carts.low .. carts.high:
      tick(carts[i], tracks)

      ## NOTE: it is very important you check for collisions immediately
      ## after ticking each individual cart (instead of after ticking them all)
      ## You have to do this so you can catch the following edge case:
      ## - before tick: -><-
      ## - after ticking both: -<>-
      ## The collision is transient between the carts two individual ticks
      var crashed = false
      for j in 0..carts.high:
        if j != i and carts[i].location == carts[j].location:
          crashed = true
          return carts[i].location

proc findLastcart*(input: string, debug: bool = false): Point =
  var (tracks, carts) = parseInput(input)

  while carts.len > 1:
    carts = carts.sorted(cmp)

    # A set of carts to clean off the tracks
    var indicesToRemove = initSet[int]()
    for i in carts.low .. carts.high:
      carts[i].tick(tracks)

      for j in carts.low .. carts.high:
        if j != i and carts[i].location == carts[j].location:
          # Take note of the two carts in this collision
          indicesToRemove.incl(i)
          indicesToRemove.incl(j)
          if debug: debugEcho "Collision @ ", carts[i].location
          break

    # Clean up the carts
    var newCarts = newSeq[Cart]()
    for i, cart in carts:
      if i notin indicesToRemove: newCarts.add(cart)
    carts = newCarts

  result = carts[0].location

when isMainModule:
  let
    input = readFile("res/day13.txt")
    firstCollision = findFirstCollision(input)

  echo firstCollision.x, ",", firstCollision.y

  let lastCart = findLastCart(input, true)
  echo lastCart.x, ",", lastCart.y


