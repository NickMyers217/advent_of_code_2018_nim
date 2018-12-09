import unittest

import ../src/day8

const testData = "2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2"

suite "Day 8 tests":
  test "Can parse a tree!":
    let tree = initNode(testData)

    check:
      tree.header.nodeCount == 2
      tree.header.entryCount == 3
      tree.entries == @[1,1,2]
      tree.children.len == 2
      tree.children[0].header.nodeCount == 0
      tree.children[0].header.entryCount == 3
      tree.children[0].entries == @[10,11,12]
      tree.children[0].children.len == 0
      tree.children[1].header.nodeCount == 1
      tree.children[1].header.entryCount == 1
      tree.children[1].entries == @[2]
      tree.children[1].children.len == 1
      tree.children[1].children[0].header.nodeCount == 0
      tree.children[1].children[0].header.entryCount == 1
      tree.children[1].children[0].entries == @[99]
      tree.children[1].children[0].children.len == 0

  test "Can total all the entries in the tree":
    let
      tree = initNode(testData)
      total = tree.totalEntries()

    check(total == 138)

  test "Can find the value of the root node in a tree":
    let tree = initNode(testData)

    check:
      tree.getValue() == 66
      tree.children[0].getValue() == 33
      tree.children[1].getValue() == 0
      tree.children[1].children[0].getValue() == 99
