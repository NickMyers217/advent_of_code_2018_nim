import unittest

import ../src/day16

suite "Day 16 Tests":
  test "Can execute an instruction":
    var registers: Registers = [0, 1, 2, 3]
    let ins: Instruction = (op: Addi, a: 1, b: 7, c: 0)
    ins.execute(registers)
    check registers == [8, 1, 2, 3]

  test "Can find the ops that fit a given test instruction":
    let
      before: Registers = [3, 2, 1, 1]
      after: Registers = [3, 2, 2, 1]
      ins: Instruction = (op: Op(9), a: 2, b: 1, c: 2)
      ops = testAllOps((before, ins, after))
    check ops == @[Addi, Mulr, Seti]

