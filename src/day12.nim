import strutils, tables, lists

type
  ## A Pot is its plant char, and its pot number
  Pot* = tuple[plant: char, index: int]
  ## A doubly linked list of `Pot`s
  PotList* = DoublyLinkedList[Pot]

proc adjust*(list: var PotList) =
  ## Adjust `list` to ensure it has the right amount of spacing
  ## on its head and tail. Also make sure to preserve the correct
  ## pot numbers of all the pots
  let
    curHeadIndex = list.head.value.index
    curTailIndex = list.tail.value.index

  proc padForApproachingPlant(
    list: var PotList,
    curNode: DoublyLinkedNode[Pot],
    forward: bool
  ) {.closure.} =
    ## Will pad extra non-plants at the head or tail
    ## when a plant is getting to close
    var node = curNode
    for i in 0 ..< 5:
      if node.value.plant == '#':
        for n in 1 .. 5:
          if forward: list.prepend(('.', curHeadIndex - n))
          else: list.append(('.', curTailIndex + n))
        break
      if forward: node = node.next
      else: node = node.prev
  
  proc trim(
    list: var PotList,
    curNode: DoublyLinkedNode[Pot],
    forward: bool
  ) {.closure.} =
    ## Will trim extra space from the head or tail when no plants
    ## are nearby
    var node = curNode
    for i in 0 ..< 10:
      if node.value.plant == '#': return
      if forward: node = node.next
      else: node = node.prev
    for i in 0 ..< 5:
      if forward: list.remove(list.head)
      else: list.remove(list.tail)
    
  list.padForApproachingPlant(list.head, true)
  list.padForApproachingPlant(list.tail, false)
  list.trim(list.head, true)
  list.trim(list.tail, false)

proc stateToList*(state: string): PotList =
  ## Parse pot `state` into a PotList
  result = initDoublyLinkedList[Pot]()
  for i, c in state:
    result.append((c, i))
  adjust(result)

proc sumPotNumbers*(list: PotList): int =
  ## Totals the pot numbers of all the `Pot`s in `list` that contain
  ## a plant
  result = 0
  for val in list.items:
    if val.plant == '#':
      result += val.index

proc listToState*(list: PotList): string =
  ## Dump a `PotList` to a string
  result = ""
  for val in list.items:
    result &= val.plant

proc nextGen*(list: PotList, lookup: Table[string, char]): PotList =
  ## Calculate the next generate of `list` using `lookup`
  result = initDoublyLinkedList[Pot]()
  var
    curNode = list.head.next.next
    endNode = list.tail.prev
  result.append(list.head.value)
  result.append(list.head.next.value)
  while curNode != endNode:
    var
      sequence = ""
      n = curNode.prev.prev
    for i in 0 ..< 5:
      sequence &= n.value.plant
      n = n.next
    result.append(curNode.value)
    result.tail.value.plant =
      if lookup.hasKey(sequence): lookup[sequence] else: '.'
    curNode = curNode.next
  result.append(list.tail.prev.value)
  result.append(list.tail.value)
  adjust(result)

proc advance*(list: PotList, lookup: Table[string ,char], n: int64): int64 =
  ## Advance `list` using `lookup` by `n` generations then
  ## return the sum of all pot numbers containing plants
  var
    listCopy = list
    lastSum, lastDiff: int64
  for i in 1 .. n:
    listCopy = listCopy.nextGen(lookup)
    let
      sum: int64 = sumPotNumbers(listCopy)
      diff = sum - lastSum
    if lastDiff == diff:
      return sum + (n - i) * diff
    lastSum = sum
    lastDiff = diff
  result = lastSum

when isMainModule:
  ## The puzzle input
  const initialState = "##.#############........##.##.####..#.#..#.##...###.##......#.#..#####....##..#####..#.#.##.#.##"
  const lookup = @[
    ("###.#", '#'), (".####", '#'), ("#.###", '.'), (".##..", '.'),
    ("##...", '#'), ("##.##", '#'), (".#.##", '#'), ("#.#..", '#'),
    ("#...#", '.'), ("...##", '#'), ("####.", '#'), ("#..##", '.'),
    ("#....", '.'), (".###.", '.'), ("..#.#", '.'), ("..###", '.'),
    ("#.#.#", '#'), (".....", '.'), ("..##.", '.'), ("##.#.", '#'),
    (".#...", '#'), ("#####", '.'), ("###..", '#'), ("..#..", '.'),
    ("##..#", '#'), ("#..#.", '#'), ("#.##.", '.'), ("....#", '.'),
    (".#..#", '#'), (".#.#.", '#'), (".##.#", '.'), ("...#.", '.')
  ].toTable()

  let list = stateToList(initialState)
  echo list.advance(lookup, 20)
  echo list.advance(lookup, 50_000_000_000)
