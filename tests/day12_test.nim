import unittest, tables, lists

import ../src/day12

const testState = "#..#.#..##......###...###"
const testLookup = @[
  ("...##", '#'), ("..#..", '#'), (".#...", '#'), (".#.#.", '#'),
  (".#.##", '#'), (".##..", '#'), (".####", '#'), ("#.#.#", '#'),
  ("#.###", '#'), ("##.#.", '#'), ("##.##", '#'), ("###..", '#'),
  ("###.#", '#'), ("####.", '#')
].toTable()

suite "Day 12 Tests":
  test "Can parse the initial state to an adjusted PotList and back":
    let list = stateTolist(testState)
    var res = listToState(list)
    check:
      res == "....." & testState & "....."
      list.head.value.index == -5
      list.tail.value.index == (testState.len - 1) + 5

  test "Can advance to the next generation":
    let list = stateToList(testState).nextGen(testLookup)
    check listToState(list) == ".....#...#....#.....#..#..#..#....."
  
  test "Can advance to the nth generation and get the sum of the pots":
    let sum = stateToList(testState).advance(testLookup, 20)
    check sum == 325
