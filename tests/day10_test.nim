import unittest, sequtils

import ../src/day10

const testData = @[
  "position=< 9,  1> velocity=< 0,  2>",
  "position=< 7,  0> velocity=<-1,  0>",
  "position=< 3, -2> velocity=<-1,  1>",
  "position=< 6, 10> velocity=<-2, -1>",
  "position=< 2, -4> velocity=< 2,  2>",
  "position=<-6, 10> velocity=< 2, -2>",
  "position=< 1,  8> velocity=< 1, -1>",
  "position=< 1,  7> velocity=< 1,  0>",
  "position=<-3, 11> velocity=< 1, -2>",
  "position=< 7,  6> velocity=<-1, -1>",
  "position=<-2,  3> velocity=< 1,  0>",
  "position=<-4,  3> velocity=< 2,  0>",
  "position=<10, -3> velocity=<-1,  1>",
  "position=< 5, 11> velocity=< 1, -2>",
  "position=< 4,  7> velocity=< 0, -1>",
  "position=< 8, -2> velocity=< 0,  1>",
  "position=<15,  0> velocity=<-2,  0>",
  "position=< 1,  6> velocity=< 1,  0>",
  "position=< 8,  9> velocity=< 0, -1>",
  "position=< 3,  3> velocity=<-1,  1>",
  "position=< 0,  5> velocity=< 0, -1>",
  "position=<-2,  2> velocity=< 2,  0>",
  "position=< 5, -2> velocity=< 1,  2>",
  "position=< 1,  4> velocity=< 2,  1>",
  "position=<-2,  7> velocity=< 2, -2>",
  "position=< 3,  6> velocity=<-1, -1>",
  "position=< 5,  0> velocity=< 1,  0>",
  "position=<-6,  0> velocity=< 2,  0>",
  "position=< 5,  9> velocity=< 1, -2>",
  "position=<14,  7> velocity=<-2,  0>",
  "position=<-3,  6> velocity=< 2, -1>"
]

suite "Day 10 tests":
  test "Can parse a Point":
    var points: seq[Point] = testData.map(initPoint)
    check:
      points[0].position == (9, 1)
      points[0].velocity == (0, 2)
      points[11].position ==  (-4, 3)
      points[11].velocity ==  (2, 0)
      points[points.high].position == (-3, 6)
      points[points.high].velocity == (2, -1)

  test "Can advance a Point by n seconds":
    let originalPoints = testData.map(initPoint)
    var testPoints = originalPoints

    for i in 0 ..< testPoints.len:
      let oldP = originalPoints[i]
      var p = testPoints[i]
      p.advance()
      check p.position == oldP.position + oldP.velocity

    for i in 0 ..< testPoints.len:
      let oldP = originalPoints[i]
      var p = testPoints[i]
      p.advance(3)
      check p.position == oldP.position + (3 * oldP.velocity)

  test "Can create a grid":
    let points = testData.map(initPoint)
    var grid = newGrid(points)

    check:
      grid.width == 22
      grid.height == 16
      grid.offset == (6, 4)
      grid.points == points
      grid.messageFound == false

  test "Can determine when a grid contains a message":
    let points = testData.map(initPoint)
    var grid = newGrid(points)

    check grid.messageFound == false
    grid.advance()
    check grid.messageFound == false
    grid.advance(2)
    check grid.messageFound == true

