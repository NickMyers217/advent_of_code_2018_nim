import unittest

import ../src/day11

const testData = @[
  # ((x, y), serial, power)
  ((3, 5), 8, 4),
  ((122, 79), 57, -5),
  ((217, 196), 39, 0),
  ((101, 153), 71, 4)
]

const moreTestData = @[
  # ((x, y), serial, totalPower)
  ((33, 45), 18, 29),
  ((21, 61), 42, 30)
]

const partTwoTestData = @[
  # ((x, y), serial, size, totalPower)
  ((90, 269), 18, 16, 113),
  ((232, 251), 42, 12, 119)
]

suite "Day 11 Tests":
  test "Can compute a powerlevel for an X,Y coordinate":
    for testCase in testData:
      let (point, serial, power) = testCase
      check computePower(point, serial) == power

  test "Can generate a grid of power levels":
    for testCase in testData:
      let
        (point, serial, power) = testCase
        grid = initGrid(serial)
      check grid.getPower(point) == power

  test "Can obtain the total power for a 3x3 section":
    for testCase in moreTestData:
      let
        (cornerPoint, serial, totalPower) = testCase
        grid = initgrid(serial)
      check grid.getTotalPower(cornerPoint) == totalPower

  test "Can find the corner of the largest 3x3 section":
    for testCase in moreTestData:
      let
        (cornerPoint, serial, totalPower) = testCase
        grid = initGrid(serial)
      check grid.getLargest3x3() == cornerPoint

  test "Can find the total power of an n by n section":
    for testCase in partTwoTestData:
      let
        (cornerPoint, serial, size, totalPower) = testcase
        grid = initGrid(serial)
      check grid.getTotalPower(cornerPoint, size) == totalPower

