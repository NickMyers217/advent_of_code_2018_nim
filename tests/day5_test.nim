import unittest

import ../src/day5

const testData = @[
  "dabAcCaCBAcCcaDA", # Full Polymer
  "dabAaCBAcCcaDA", # Remove cC
  "dabCBAcCcaDA", # Remove Aa
  "dabCBAcaDA" # Remove cC, none left
]

suite "Day 5 tests":
  test "Can determine if a unit will react":
    check:
      isReaction("aA") == true
      isReaction("Aa") == true
      isReaction("aa") == false
      isReaction("AA") == false
      isReaction("ab") == false
      isReaction("cF") == false
      isReaction("zZ") == true

  test "Can iterate the units of a polymer":
    var units: seq[string] = @[]
    for i, unit in testData[3].unitPairs():
      units.add(unit)
    check(units == @[ "da", "ab", "bC", "CB", "BA", "Ac", "ca", "aD", "DA" ])
    units = @[]
    for i, unit in "aBc".unitPairs(): units.add(unit)
    check(units == @[ "aB", "Bc"])

  test "Can trigger the first reaction in a polymer":
    var polymer = testData[0]
    polymer.trigger(1)
    check(polymer == testData[1])
    polymer.trigger(1)
    check(polymer == testData[2])
    polymer.trigger(1)
    check(polymer == testData[3])

  test "Can exhaust all the reactions in a polymer":
    var polymer = testData[0]
    polymer.trigger()
    check(polymer == testData[3])

  test "Can count the amount of units in a polymer":
    check:
      testData[0].len() == 16
      testData[1].len() == 14
      testData[2].len() == 12
      testData[3].len() == 10

  test "Can eliminate a type from a polymer":
    var polymer = testData[0]
    check:
      polymer.eliminate('a') == "dbcCCBcCcD"
      polymer.eliminate('b') == "daAcCaCAcCcaDA"
      polymer.eliminate('c') == "dabAaBAaDA"
      polymer.eliminate('d') == "abAcCaCBAcCcaA"
      polymer.eliminate('e') == "dabAcCaCBAcCcaDA"

  test "Can compact a polymer and find its length":
    var polymer = testData[0]
    check:
      polymer.compact('a', false) == 5
      polymer.compact('b', false) == 7
      polymer.compact('c', false) == 3
      polymer.compact('d', false) == 5

  test "Can find the most compact polymer":
    var polymer = testData[0]
    check(polymer.findMostCompact(false) == 3)
