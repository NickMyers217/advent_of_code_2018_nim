import lists, strutils, strscans

type
  Player* = tuple[id, score: int]

  ## Stores information about a game
  Game* = ref object
    curMarble* : int # The current marble
    finalMarble*: int # The last marble that should play
    players*: seq[Player] # The players
    curPlayer*: int # The index of the player who will make this turn
    circle*: DoublyLinkedRing[int] # The circle of marbles

func newGame*(numPlayers, finalMarble: int): Game =
  ## Initialize a new `Game`
  var
    players: seq[Player] = @[]
    circle = initDoublyLinkedRing[int]()

  for id in 1 .. numPlayers:
    players.add((id: id, score: 0))

  circle.prepend(0)

  result = Game(
    curMarble: 1,
    finalMarble: finalMarble,
    players: players,
    curPlayer: 0,
    circle: circle
  )

func isFinished*(game: Game): bool =
  result = game.curMarble == game.finalMarble

func findHighestScore*(game: Game): int =
  result = 0
  for player in game.players:
    if player.score > result: result = player.score

proc advance*(game: Game, numTurns: int = 1): bool =
  ## Advance the game by a turn returns true if game is complete
  result = false

  for i in 0 ..< numTurns:
    if game.isFinished: return true

    if (game.curMarble mod 23) == 0:
      var nodeToRemove = game.circle.head
      for i in 0 ..< 7: nodeToRemove = nodeToRemove.prev
      game.players[game.curPlayer].score += game.curMarble
      game.players[game.curPlayer].score += nodeToRemove.value
      game.circle.head  = nodeToRemove.next
      game.circle.remove(nodeToRemove)
    else:
      game.circle.head = game.circle.head.next.next
      game.circle.prepend(game.curMarble)

    inc game.curMarble
    inc game.curPlayer
    if game.curPlayer == game.players.len: game.curPlayer = 0

func `$`*(game: Game): string =
  ## Print out the game
  result = """
  {
    curMarble: $1,
    finalMarble: $2,
    highScore: $3,
    circle: <-- ... $3, ($4), $5 ... -->
  }
  """ % [
    $game.curMarble,
    $game.finalMarble,
    $game.findHighestScore(),
    $game.circle.head.prev.value,
    $game.circle.head.value,
    $game.circle.head.next.value
  ]

proc printAnswers*(input: string) =
  var numPlayers, finalMarble: int
  discard input.scanf(
    "$i players; last marble is worth $i points",
    numPlayers,
    finalMarble
  )

  var game = newGame(numPlayers, finalMarble)
  if game.advance(finalMarble): echo game
  else: echo "SOMETHING TERRIBLE IS WRONG"

  var bigAssGame = newGame(numPlayers, finalMarble * 100)
  if bigAssGame.advance(finalMarble * 100): echo bigAssGame
  else: echo "SOMETHING TERRIBLE IS WRONG"

when isMainModule:
  const puzzleInput = "478 players; last marble is worth 71240 points"
  printAnswers(puzzleInput)

