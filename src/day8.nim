import strutils, sequtils, queues

type
  Node* = object
    header*: tuple[nodeCount, entryCount: int]
    children*: seq[Node]
    entries*: seq[int]

func initNode*(numbers: seq[int]): Node =
  # A node must have 2 numbers in the header, and at least 1 entry
  assert numbers.len >= 3
  result = Node()

  # Make a queue out of numbers
  var nums = initQueue[int]()
  for n in numbers: nums.enqueue(n)

  proc walk(): Node {.closure.} =
    # Recursive closure to help walk the tree
    if nums.len == 0: return Node(header: (0, 0), children: @[], entries: @[])
    result =
      Node(header: (nums.dequeue, nums.dequeue), children: @[], entries: @[])
    for child in 0 ..< result.header.nodeCount:
      result.children.add(walk())
    for entry in 0 ..< result.header.entryCount:
      result.entries.add(nums.dequeue())

  result = walk()

func initNode*(licenseFile: string): Node =
  result = initNode(licenseFile.split().map(parseInt))

func totalEntries*(node: Node): int =
  ## Walk the tree while totaling the entries
  result = node.entries.foldl(a + b, 0)
  if node.children.len > 0:
    for node in node.children:
      result += totalEntries(node)

func getValue*(node: Node): int =
  ## Calculate the value of this tree
  if node.children.len == 0:
    return node.entries.foldl(a + b, 0)
  result = 0
  for e in node.entries:
    let i = e - 1
    if i >= 0 and i < node.children.len:
      result += getValue(node.children[i])

proc printAnswers*(filePath: string) =
  let
    input = readFile(filePath).splitLines()[0]
    tree = initNode(input)
  echo tree.totalEntries()
  echo tree.getValue()

when isMainModule:
  printAnswers("res/day8.txt")

