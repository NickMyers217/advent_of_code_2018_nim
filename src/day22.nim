import strutils, sequtils

type
  Vec = tuple[x, y: int]
  Region = enum Rocky, Wet, Narrow
  Cell = tuple
    geologicalIndex, erosionLevel: int
    region: Region
  Map = seq[seq[Cell]]
  Cave = ref object
    width, depth: int
    targetLocation: Vec
    map: Map

## Vector math helpers
proc `-`(a, b: Vec): Vec {.inline.} = (x: a.x - b.x, y: a.y - b.y)
proc `+`(a, b: Vec): Vec {.inline.} = (x: a.x + b.x, y: a.y + b.y)
proc `*`(a: int, b: Vec): Vec {.inline.} = (x: a * b.x, y: a * b.y)
proc inc(a: var Vec, b: Vec) {.inline.} = a = a + b
proc dec(a: var Vec, b: Vec) {.inline.} = a = a - b
proc down(a: Vec): Vec {.inline.} = a + (0,1)
proc up(a: Vec): Vec {.inline.} = a - (0,1)
proc right(a: Vec): Vec {.inline.} = a + (1,0)
proc left(a: Vec): Vec {.inline.} = a - (1,0)

proc calcGeologicalIndex(map: Map, vec, target: Vec): int =
  if vec == (0, 0):
    return 0
  elif vec == target:
    return 0
  elif vec.x == 0:
    return vec.y * 48271
  elif vec.y == 0:
    return vec.x * 16807
  else:
    return map[vec.left.y][vec.left.x].erosionLevel * map[vec.up.y][vec.up.x].erosionLevel

proc calcErosionLevel(geologicalIndex, depth: int): int =
  (geologicalIndex + depth) mod 20183

proc calcRegion(erosionLevel: int): Region =
  case erosionLevel mod 3
  of 0: return Rocky
  of 1: return Wet
  of 2: return Narrow
  else: discard

proc `$`(cave: Cave): string =
  result = ""
  for y, row in cave.map:
    for x, col in row:
      if (x, y) == (0, 0):
        result &= 'M'
      elif (x, y) == cave.targetLocation:
        result &= 'T'
        return
      else:
        case col.region
        of Rocky: result &= '.'
        of Wet: result &= '='
        of Narrow: result &= '|'
    result &= '\n'

proc newCave(depth: int, targetLocation: Vec): Cave =
  let width = targetLocation.x + 1
  var map: Map = newSeqWith(depth, newSeq[Cell](width))

  for y, row in map:
    for x, col in row:
      let
        geologicalIndex = map.calcGeologicalIndex((x, y), targetLocation)
        erosionLevel = calcErosionLevel(geologicalIndex, depth)
        region = calcRegion(erosionLevel)
      map[y][x] = (geologicalIndex, erosionLevel, region)

  result = Cave(
    width: width,
    depth: depth,
    targetLocation: targetLocation,
    map: map
  )

proc calcTotalRiskLevel(cave: Cave): int =
  result = 0
  for y, row in cave.map:
    for x, col in row:
      case col.region
      of Rocky: inc result, 0
      of Wet: inc result
      of Narrow: inc result, 2

      if (x, y) == cave.targetLocation:
        return


when isMainModule:
  let input = (9465, (13,704))
  let testInput = (510, (10,10))

  echo newCave(input[0], input[1]).calcTotalRiskLevel()

