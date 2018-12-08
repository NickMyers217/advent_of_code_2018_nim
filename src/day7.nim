import strscans, strutils, sequtils, tables

type
  ## A `dependency` that must be fulfilled before `step` can be taken
  Instruction* = tuple[dependency, step: char]

  ## A `Graph` is just a table of nodes A node's key is a capital letter and its value contains,
  ## - `prevSteps` the nodes that pointed here
  ## - `nextSteps` the nodes that come next
  ## - `isStart` and `isEnd` to indicate if this node is a start or end point of the graph
  NodeValue* = tuple[prevNodes, nextNodes: set[char], isStart, isEnd: bool]
  Graph* = Table[char, NodeValue]

func initInstruction*(input: string): Instruction =
  var d, s: string
  if input.scanf("Step $w must be finished before step $w can begin.", d, s):
    result = (d[0], s[0])

func initGraph*(instructions: seq[Instruction]): Graph =
  ## Initialize a graph by processing a seq of `Instruction`s
  result = initTable[char, NodeValue]()

  # Process each instruction and set up prevNodes and nextNodes
  for ins in instructions:
    discard result.hasKeyOrPut(ins.dependency, ({}, {}, false, false))
    discard result.hasKeyOrPut(ins.step, ({}, {}, false, false))
    result[ins.dependency].nextNodes.incl(ins.step)
    result[ins.step].prevNodes.incl(ins.dependency)

  # Make a second pass to determine which nodes are starts and ends
  for key, node in result.pairs:
    # Nothing came before this node, so it is a start
    if node.prevNodes == {}: result[key].isStart = true
    # Nothing came after this node, so it is an end
    if node.nextNodes == {}: result[key].isEnd = true

func kahnsAlgorithm*(graph: Graph): string  =
  ## Iterate the dependcy graph using kahn's algorithm to build a string of nodes
  result = ""
  var
    graphCopy = graph
    depsMet: set[char] = {} # The nodes available to be processed

  # Find all the initially available start nodes
  for key, node in graphCopy.pairs:
    if node.isStart: depsMet.incl(key)

  while depsMet != {}:
    var
      nodeName: char
      node: NodeValue

    # couldnt find a better way to get the first element out of the set :(
    for n in items[char](depsMet):
      nodeName = n
      node = graphCopy[n]
      depsMet.excl(nodeName)
      break
    result &= nodeName

    # Remove the edges between nodeName and its next nodes
    for key in items[char](node.nextNodes):
      graphCopy[key].prevNodes.excl(nodeName)
      # If the node has all its deps met, add it to depsMet
      if graphCopy[key].prevNodes == {}: depsMet.incl(key)
    node.nextNodes = {}

proc printAnswers*(filePath: string, debug: bool = false) =
  let
    input = readFile(filePath)
      .splitLines()
      .filter(proc(e: string): bool = e != "")
    instructions = input.map(initInstruction)
    graph = initGraph(instructions)
    output = graph.kahnsAlgorithm()

  if debug:
    for key, val in graph.pairs: echo "{ ", key, ": ", val, "}"
    echo "\n============================================\n"
    for c in output: echo "{ ", c, ": ", graph[c].nextNodes, " }"
    echo "\n============================================\n"

  echo output

when isMainModule:
  printAnswers("res/day7.txt")
