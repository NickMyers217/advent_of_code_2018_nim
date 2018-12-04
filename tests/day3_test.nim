import unittest, sequtils

import ../src/day3

const testData = @[
  "#1 @ 1,3: 4x4",
  "#2 @ 3,1: 4x4",
  "#3 @ 5,5: 2x2"
]

suite "Day 3 tests":
  test "Can parse a rectangle":
    let parsedRect = initRect("#23 @ 10,2: 23x5")
    check:
      parsedRect.id == 23
      parsedRect.x == 10
      parsedRect.y == 2
      parsedRect.width == 23
      parsedRect.height == 5

  test "Can render a rectangle as a string":
    let parsedRect = initRect(testData[0])
    check($parsedRect == testData[0])

  test "Can create a new Grid":
    let grid = newGrid(3, 2);
    check:
      grid.width == 3
      grid.height == 2
      grid.values.len() == grid.width * grid.height
      grid.values == @[0, 0, 0, 0, 0, 0]

  test "Can mark a points on a grid":
    var grid = newGrid(3, 2)
    grid.mark((0, 0))
    grid.mark((1, 0))
    grid.mark((1, 0))
    grid.mark((2, 1))
    check(grid.values == @[
      1, 2, 0,
      0, 0, 1
    ])

  test "Can mark rects on a grid":
    var grid = newGrid(7, 5)
    let rects = @[
      initRect("#1 @ 1,2: 3x2"),
      initRect("#2 @ 3,1: 2x2"),
      initRect("#3 @ 4,2: 2x2"),
      initRect("#4 @ 6,0: 1x1"),
      initRect("#4 @ 2,0: 3x5"),
    ]

    for rect in rects:
      grid.mark(rect)

    check(grid.values == @[
      0, 0, 1, 1, 1, 0, 1,
      0, 0, 1, 2, 2, 0, 0,
      0, 1, 2, 3, 3, 1, 0,
      0, 1, 2, 2, 2, 1, 0,
      0, 0, 1, 1, 1, 0, 0
    ])

  test "Can verify if a rect does not overlap another":
    var grid = newGrid(7, 7)
    let rects = testData.map(initRect)

    for rect in rects:
      grid.mark(rect)

    let overlaps = rects
      .filter(proc(e: Rect): bool = grid.doesNotOverlap(e))
      .map(proc(e: Rect): int = e.id)

    check(overlaps == @[3])

  test "Can log the answer for part one and two":
    printAnswers("res/day3.txt")
    require(true)

