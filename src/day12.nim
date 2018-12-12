import strutils, tables, lists

type
  Pot* = tuple[plant: char, index: int]
  PotList* = DoublyLinkedList[Pot]

proc expandList*(list: var PotList) =
  let
    curHeadIndex = list.head.value.index
    curTailIndex = list.tail.value.index

  var curHeadNode = list.head
  for i in 0 ..< 5:
    if curHeadNode.value.plant == '#':
      for n in 1 .. 10: list.prepend(('.', curHeadIndex - n))
      break
    curHeadNode = curHeadNode.next

  var curTailNode = list.tail
  for i in 0 ..< 5:
    if curTailNode.value.plant == '#':
      for n in 1 .. 10: list.append(('.', curTailIndex + n))
      break
    curTailNode = curTailNode.prev

  var needToTrimHead = true
  curHeadNode = list.head
  for i in 0 ..< 10:
    if curHeadNode.value.plant == '#':
      needToTrimHead = false
      break
    curHeadNode = curHeadNode.next

  if needToTrimHead:
    for i in 0 ..< 5: list.remove(list.head)

proc stateToList*(state: string): PotList =
  result = initDoublyLinkedList[Pot]()
  for i, c in state:
    result.append((c, i))
  expandList(result)

proc sumPlantIndices*(list: PotList): int =
  result = 0
  for val in list.items:
    if val.plant == '#':
      result += val.index

proc listToState*(list: PotList): string =
  result = ""
  for val in list.items:
    result &= val.plant

proc nextGen*(list: PotList, lookup: Table[string, char]): PotList =
  result = initDoublyLinkedList[Pot]()
  var
    startN = list.head.next.next
    endN = list.tail.prev
  result.append(list.head.value)
  result.append(list.head.next.value)
  while startN != endN:
    var sequence = ""
    sequence &= startN.prev.prev.value.plant
    sequence &= startN.prev.value.plant
    sequence &= startN.value.plant
    sequence &= startN.next.value.plant
    sequence &= startN.next.next.value.plant
    result.append(startN.value)
    result.tail.value.plant = (if lookup.hasKey(sequence): lookup[sequence] else: '.')
    startN = startN.next
  result.append(list.tail.prev.value)
  result.append(list.tail.value)
  expandList(result)

when isMainModule:
  const initialState = "##.#############........##.##.####..#.#..#.##...###.##......#.#..#####....##..#####..#.#.##.#.##"
  const lookup = @[
    ("###.#", '#'), (".####", '#'), ("#.###", '.'), (".##..", '.'), ("##...", '#'), ("##.##", '#'), (".#.##", '#'), ("#.#..", '#'), ("#...#", '.'), ("...##", '#'), ("####.", '#'), ("#..##", '.'), ("#....", '.'), (".###.", '.'), ("..#.#", '.'), ("..###", '.'), ("#.#.#", '#'), (".....", '.'), ("..##.", '.'), ("##.#.", '#'), (".#...", '#'), ("#####", '.'), ("###..", '#'), ("..#..", '.'), ("##..#", '#'), ("#..#.", '#'), ("#.##.", '.'), ("....#", '.'), (".#..#", '#'), (".#.#.", '#'), (".##.#", '.'), ("...#.", '.')
  ].toTable()
  #const initialState = "#..#.#..##......###...###"
  #const lookup = @[
  #  ("...##", '#'), ("..#..", '#'), (".#...", '#'), (".#.#.", '#'), (".#.##", '#'), (".##..", '#'), (".####", '#'), ("#.#.#", '#'), ("#.###", '#'), ("##.#.", '#'), ("##.##", '#'), ("###..", '#'), ("###.#", '#'), ("####.", '#')
  #].toTable()
  let list = stateToList(initialState)

  var listCopy = list
  #echo listToState listCopy
  #echo listCopy
  echo listToState listCopy
  var lastSum, lastDiff, finalSum: int64
  for i in 1 .. 200: #50_000_000_000:
    listCopy = listCopy.nextGen(lookup)
    #echo listToState listCopy
    let
      sum: int64 = sumPlantIndices(listCopy)
      diff = sum - lastSum
    echo i, ": ", sum, " Diff: ", diff

    if lastDiff == diff:
      finalSum = sum + (50_000_000_000 - i) * diff
      break

    lastSum = sum
    lastDiff = diff

  #echo listCopy
  echo listToState listCopy
  echo sumPlantIndices(listCopy)
  echo finalSum


