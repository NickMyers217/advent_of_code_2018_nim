import lists, sequtils, strutils, queues

## The puzzle input
const input = 824501

type
  ## A seq of all the recipe scores
  RecipeList = seq[int]
  ## An Elf is an index for the recipe list
  Elf = int
  ## The elves
  Elves = array[2, Elf]

proc newRecipeList(size: int): RecipeList =
  ## Produce the initial state for a `RecipeList` of `size`
  # NOTE: I experimented with using an array instead, which worked great for part one,
  # but on part two i think its size exceeded my stack memory (was just getting a seg fault).
  # I switched to using a seq for the heap allocation, but took care to manually
  # assign the length here to avoid frequent and expensive reallocations.
  result = newSeq[int](size)
  result[0] = 3
  result[1] = 7

proc newElves(): Elves =
  ## Set up the initial state of the `Elves`
  result[0] = 0
  result[1] = 1

proc partOne*(recipeLimit: int, amountToCount: int = 10): string =
  ## Finds the scores of the `amountToCount` recipes that come after
  ## the `recipeLimit`
  result = ""
  var
    recipes = newRecipeList(recipeLimit + amountToCount)
    elves = newElves()
    recipesCreated = 2

  while recipesCreated < (recipeLimit + amountToCount):
    let
      sum = elves.mapIt(recipes[it]).foldl(a + b)
      digits = $sum

    for d in digits:
      if recipesCreated < (recipeLimit + amountToCount):
        recipes[recipesCreated] = int(d) - 48 # ascii magic
        inc recipesCreated

    for i in elves.low .. elves.high:
      let
        stepsToMove = recipes[elves[i]] + 1
        nextIndex = (elves[i] + stepsToMove) mod recipesCreated
      elves[i] = nextIndex

  result &= recipes[recipeLimit ..< (recipeLimit + amountToCount)].join("")

proc partTwo*(matchText: string): int64 =
  ## Continues to add recipes until we find consecutive recipes that match `matchText`
  ## then return the amount of recipes it took to get to the match
  var
    recipes = newRecipeList(input * 32) # I manually fiddled with the size
    elves = newElves()
    recipesCreated = 2
    matchFound = false
    testStr = ""

  while not matchFound:
    let
      sum = elves.mapIt(recipes[it]).foldl(a + b)
      digits = $sum

    for d in digits:
      recipes[recipesCreated] = int(d) - 48
      inc recipesCreated
      testStr &= d

      if testStr.len == matchText.len:
        if testStr == matchText:
          matchFound = true
          break
        else:
          testStr = testStr.substr(1)

    for i in elves.low .. elves.high:
      let
        stepsToMove = recipes[elves[i]] + 1
        nextIndex = (elves[i] + stepsToMove) mod recipesCreated
      elves[i] = nextIndex

  result = recipesCreated - matchText.len

when isMainModule:
  echo partOne(input)
  echo partTwo($input)

