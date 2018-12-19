import unittest

import ../src/day19

const testInput = """
#ip 0
seti 5 0 1
seti 6 0 2
addi 0 1 0
addr 1 2 3
setr 1 0 0
seti 8 0 4
seti 9 0 5
"""

suite "Day 19 Tests":
  test "Can execute a test program on some registers":
    var before = [ 0, 0, 0, 0, 0, 0 ]
    let
      after = [ 6, 5, 6, 0, 0, 9 ]
      program = testInput.parseProgram()
    program.execute(before)
    check before == after

  test "Can compute the sum of the divisors for a number in register 5, and put it in register 0":
    var before = [ 0, 0, 0, 0, 0, 6 ]
    let program = testInput.parseProgram()
    program.execute(before, true)
    check before[0] == 12
