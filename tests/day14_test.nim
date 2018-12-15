import unittest

import ../src/day14

suite "Day 14 Tests":
  test "Can get the scores of the 10 recipes after the first n recipes":
    check:
      partOne(9) == "5158916779"
      partOne(5) == "0124515891"
      partOne(18) == "9251071085"
      partOne(2018) == "5941429882"

  test "Can find the amount of scores that come before a certain sequence":
    check:
      partTwo("51589") == 9
      partTwo("01245") == 5
      partTwo("92510") == 18
      partTwo("59414") == 2018
