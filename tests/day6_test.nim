import unittest, sequtils

import ../src/day6

const testData = @[
  "1, 1",
  "1, 6",
  "8, 3",
  "3, 4",
  "5, 5",
  "8, 9"
]

const testGrid = @[
  [0,0,0,0,0,-1,2,2,2,2],
  [0,0,0,0,0,-1,2,2,2,2],
  [0,0,0,3,3,4,2,2,2,2],
  [0,0,3,3,3,4,2,2,2,2],
  [-1,-1,3,3,3,4,4,2,2,2],
  [1,1,-1,3,4,4,4,4,2,2],
  [1,1,1,-1,4,4,4,4,-1,-1],
  [1,1,1,-1,4,4,4,5,5,5],
  [1,1,1,-1,4,4,5,5,5,5],
  [1,1,1,-1,5,5,5,5,5,5]
]

suite "Day 6 tests":
  test "Can parse a Vec":
    let points = testData.map(initVec)
    check:
      points[0].x == 1 and points[0].y == 1
      points[1].x == 1 and points[1].y == 6
      points[2].x == 8 and points[2].y == 3
      points[3].x == 3 and points[3].y == 4
      points[4].x == 5 and points[4].y == 5
      points[5].x == 8 and points[5].y == 9

  test "Can compute manhattan distance between two Vecs":
    check:
      manhattan((-1, -1), (2, 3)) == 7
      manhattan(( 1,  1), (2, 3)) == 3
      manhattan(( 5,  5), (5, 2)) == 3
      manhattan(( 3,  4), (5, 2)) == 4
      manhattan(( 1,  1), (5, 2)) == 5

  test "Can create the Grid":
    let points = testData.map(initVec)
    var grid = newGrid(points)

    grid.markClosest()
    check(grid.points == points)

    # We need a much bigger hardcoded grid for the actual solution
    # for tests we trim it down to a 9x9 grid
    for y in 0 ..< 10:
      for x in 0 ..< 10:
        check(grid.values[y][x] == testGrid[y][x])

  test "Can determine which points will have infinite areas":
    let points = testData.map(initVec)
    var grid = newGrid(points)

    grid.markClosest()
    check(grid.getInfinites() == { 0, 1, 2, 5 })

  test "Can find the largest non-infinite area":
    let points = testData.map(initVec)
    var grid = newGrid(points)

    grid.markClosest()
    check(grid.largestArea() == 17)

  test "Can find the size of the safe region ":
    let points = testData.map(initVec)
    var grid = newGrid(points)
    grid.markPointsWithTotalLessThan(32)
    check(grid.safeArea() == 16)

  test "Can print the answers!":
    printAnswers("res/day6.txt")
    require(true)
