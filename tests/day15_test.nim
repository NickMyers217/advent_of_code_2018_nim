import unittest, strutils, sequtils

import ../src/day15

const movementTest = """
#########
#G..G..G#
#.......#
#.......#
#G..E..G#
#.......#
#.......#
#G..G..G#
#########
"""

const movementTestResult = """
#########
#.......#
#..GGG..#
#..GEG..#
#G..G...#
#......G#
#.......#
#.......#
#########
""".splitLines().filterit(it != "")

const attackTest = """
#######
#.G...#
#...EG#
#.#.#G#
#..G#E#
#.....#
#######
"""

const attackTestResult = """
#######   
#G....#   G(200)
#.G...#   G(131)
#.#.#G#   G(59)
#...#.#   
#....G#   G(200)
#######   
""".splitLines().filterIt(it != "")

const testGame1 = """
#######
#G..#E#
#E#E.E#
#G.##.#
#...#E#
#...E.#
#######
"""
const testGame1Result = """
#######   
#...#E#   E(200)
#E#...#   E(197)
#.E##.#   E(185)
#E..#E#   E(200), E(200)
#.....#   
#######   
""".splitLines().filterIt(it != "")
const testGame1Score = 36334

const testGame2 = """
#######
#E..EG#
#.#G.E#
#E.##E#
#G..#.#
#..E#.#
#######
"""
const testGame2Result = """
#######   
#.E.E.#   E(164), E(197)
#.#E..#   E(200)
#E.##.#   E(98)
#.E.#.#   E(200)
#...#.#   
#######   
""".splitLines().filterIt(it != "")
const testGame2Score = 39514

const testGame3 = """
#######
#E.G#.#
#.#G..#
#G.#.G#
#G..#.#
#...E.#
#######
"""
const testGame3Result = """
#######   
#G.G#.#   G(200), G(98)
#.#G..#   G(200)
#..#..#   
#...#G#   G(95)
#...G.#   G(200)
#######   
""".splitLines().filterIt(it != "")
const testGame3Score = 27755

const testGame4 = """
#######
#.E...#
#.#..G#
#.###.#
#E#G#G#
#...#G#
#######
"""
const testGame4Result = """
#######   
#.....#   
#.#G..#   G(200)
#.###.#   
#.#.#.#   
#G.G#G#   G(98), G(38), G(200)
#######   
""".splitLines().filterIt(it != "")
const testGame4Score = 28944

const testGame5 = """
#########
#G......#
#.E.#...#
#..##..G#
#...##..#
#...#...#
#.G...G.#
#.....G.#
#########
"""
const testGame5Result = """
#########   
#.G.....#   G(137)
#G.G#...#   G(200), G(200)
#.G##...#   G(200)
#...##..#   
#.G.#...#   G(200)
#.......#   
#.......#   
#########   
""".splitLines().filterIt(it != "")
const testGame5Score = 18740

suite "Day 15 Tests":
  test "Can observe correct path finding for simple 3 round test":
    var game = newGame(movementTest)
    game.advanceRound()
    game.advanceRound()
    game.advanceRound()
    check:
      game.round == 3
      ($game).splitLines().filterIt(it != "") == movementTestResult

  test "Can play through a simple match and get the correct result":
    var game = newGame(attackTest)
    game.play()
    check:
      game.renderWithHpInfo().splitLines().filterIt(it != "") == attackTestResult
      game.round == 47
      game.tallyScore() == 27730

  test "Can correctly play several test games and tally their scores":
    var game1 = newGame(testGame1)
    game1.play()
    check:
      game1.renderWithHpInfo().splitLines().filterIt(it != "") == testGame1Result
      game1.round == 37
      game1.tallyScore() == testGame1Score

    var game2 = newGame(testGame2)
    game2.play()
    check:
      game2.renderWithHpInfo().splitLines().filterIt(it != "") == testGame2Result
      game2.round == 46
      game2.tallyScore() == testGame2Score

    var game3 = newGame(testGame3)
    game3.play()
    check:
      game3.renderWithHpInfo().splitLines().filterIt(it != "") == testGame3Result
      game3.round == 35
      game3.tallyScore() == testGame3Score

    var game4 = newGame(testGame4)
    game4.play()
    check:
      game4.renderWithHpInfo().splitLines().filterIt(it != "") == testGame4Result
      game4.round == 54
      game4.tallyScore() == testGame4Score

    var game5 = newGame(testGame5)
    game5.play()
    check:
      game5.renderWithHpInfo().splitLines().filterIt(it != "") == testGame5Result
      game5.round == 20
      game5.tallyScore() == testGame5Score
