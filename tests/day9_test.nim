import unittest, lists

import ../src/day9

const testData = @[
  # (numPlayers, finalMarble, highScore)
  (10, 1618, 8317),
  (9, 25, 32),
  (13, 7999, 146373),
  (21, 6111, 54718),
  (30, 5807, 37305)
]

suite "Day 9 tests":
  test "Can parse a Game":
    let game = newGame(testData[0][0], testData[0][1])
    check:
      game.curMarble == 1
      game.finalMarble == 1618
      game.players.len == 10
      game.curPlayer == 0
      game.circle.head.value == 0

  test "Can advance the game state on a non scoring turn":
    var game = newGame(testData[0][0], testData[0][1])

    check:
      game.advance() == false
      game.curMarble == 2
      game.finalMarble == 1618
      game.curPlayer == 1
      game.circle.head.value == 1
      game.circle.head.prev.value == 0
      game.circle.head.next.value == 0

      game.advance(10) == false
      game.curMarble == 12
      game.finalMarble == 1618
      game.curPlayer == 1
      game.circle.head.value == 11
      game.circle.head.prev.value == 5
      game.circle.head.next.value == 1

  test "Can advance the game on a scoring turn":
    var game = newGame(testData[1][0], testData[1][1])

    check:
      game.advance(23) == false
      game.curMarble == 24
      game.curPlayer == 5
      $game.circle == "[19, 2, 20, 10, 21, 5, 22, 11, 1, 12, 6, 13, 3, 14, 7, 15, 0, 16, 8, 17, 4, 18]"

    for player in game.players:
      if player.id != 5: check player.score == 0
      else: check player.score == 32

  test "Can advance a game to its final state and get the right score":
    for testCase in testData:
      var
        (players, final, score) = testCase
        game = newGame(players, final)
      check:
        game.advance(final) == true
        game.findHighestScore() == score

