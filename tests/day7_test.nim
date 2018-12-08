import unittest, sequtils, tables

import ../src/day7

const testData = @[
  "Step C must be finished before step A can begin.",
  "Step C must be finished before step F can begin.",
  "Step G must be finished before step F can begin.",
  "Step A must be finished before step B can begin.",
  "Step A must be finished before step D can begin.",
  "Step B must be finished before step E can begin.",
  "Step D must be finished before step E can begin.",
  "Step F must be finished before step E can begin."
]

suite "Day 7 tests":
  test "Can parse an instruction":
    let
      instruction1 = initInstruction(testData[0])
      instruction2 = initInstruction(testData[1])

    check:
      instruction1.dependency == 'C'
      instruction1.step == 'A'
      instruction2.dependency == 'C'
      instruction2.step == 'F'

  test "Can find the starting and ending points of a graph":
    let graph = initGraph(testData.map(initInstruction))

    var startNodes, endNodes: seq[char] = @[]
    for key, node in graph:
      if node.isStart: startNodes.add(key)
      if node.isEnd: endNodes.add(key)

    check:
      startNodes == @['C', 'G']
      endNodes == @['E']

  test "Can walk the graph using Kahn's algorithm and build the correct list of steps":
    let
      graph = initGraph(testData.map(initInstruction))
      output = graph.kahnsAlgorithm()
    var seen: set[char] = {}
    for c in output:
      check(c notin seen)
      seen.incl(c)
    check(output == "CABDGFE")

