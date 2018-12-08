import strscans, strutils, sequtils, tables, algorithm

type
  ## A `dependency` that must be fulfilled before `step` can be taken
  Instruction* = tuple[dependency, step: char]

  Status* = enum IDLE, BUSY, COMPLETE

  ## A worker who is accomplishing a task
  Worker* = ref object
    nodeName: char
    status: Status
    timeStarted, duration: int

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

func newWorker*(): Worker =
  result = Worker()

func `$`*(worker: Worker): string =
  case worker.status
  of BUSY:
    result = "[$1] Started work on $2 at $3. Will finish at $4 seconds" % [
      $worker.status,
      $worker.nodeName,
      $worker.timeStarted,
      $(worker.timeStarted + worker.duration)
    ]
  of IDLE:
    result = "[$1] Running idle." % [ $worker.status, ]
  of COMPLETE:
    result = "[$1] Finished work on $2 at $3!" % [
      $worker.status,
      $worker.nodeName,
      $(worker.timeStarted + worker.duration)
    ]


proc checkIfDone*(worker: var Worker, time: int) =
  ## Updates a worker to COMPLETE status when their task is over
  if time - worker.timeStarted >= worker.duration:
    worker.status = COMPLETE

proc assign*(worker: var Worker, nodeName: char, time, baseTaskTime: int) =
  ## Assign a worker to a new task
  worker.status = BUSY
  worker.nodeName = nodeName
  worker.timeStarted = time
  worker.duration = baseTaskTime + (int(nodeName) - 64)

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

func kahnsAlgorithmWithScheduling*(
  graph: Graph,
  workerCount: int,
  baseTaskTime: int,
  debug: bool = false
): int =
  ## Iterate the dependcy graph using kahn's algorithm
  ## BUT THIS TIME WITH SCHEDULING to find out how long it will take
  var
    time = 0
    nodeOrder = ""
    workers: seq[Worker] = @[]
    graphCopy = graph
    depsMet: set[char] = {} # The nodes available to be processed

  # Set up the workers
  for w in 0 ..< workerCount: workers.add(newWorker())

  # Find all the initially available start nodes
  for key, node in graphCopy.pairs:
    if node.isStart: depsMet.incl(key)

  proc handleWorker(w: var Worker, number: int) {.closure.} =
    if w.status == IDLE:
      if debug: echo "Worker ", number, ": ", w
      for n in items[char](depsMet):
        workers[number].assign(n, time, baseTaskTime)
        depsMet.excl(n)
        break
    if w.status == BUSY:
      if debug: echo "Worker ", number, ": ", w
      workers[number].checkIfDone(time)
    if w.status == COMPLETE:
      if debug: echo "Worker ", number, ": ", w
      for key in items[char](graphCopy[w.nodeName].nextNodes):
        graphCopy[key].prevNodes.excl(w.nodeName)
        if graphCopy[key].prevNodes == {}:
          depsMet.incl(key)
      if debug: echo "\t=> Tasks: ", depsMet
      graphCopy[w.nodeName].nextNodes = {}
      nodeOrder &= w.nodeName
      workers[number].status = IDLE # ready to work!
      handleWorker(w, number) # go around again and snatch up the next task

  while workers.filter(proc(w: Worker): bool = w.status == BUSY).len > 0 or depsMet != {}:
    if debug: echo "Time: ", time, " Tasks: ", depsMet
    for i in workers.low .. workers.high:
      handleWorker(workers[i], i)
    if debug: echo "\n"
    var times = workers
      .filter(proc(w: Worker): bool = w.status == BUSY)
      .map(proc(w: Worker): int = w.timeStarted + w.duration)
      .sorted(cmp[int])
    # step to the next time something will finish
    if times.len > 0:
      if debug: echo times
      time = times[0]
    else: inc time

  if debug: echo nodeOrder
  result = time - 1


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

  if debug: echo "\n============================================\n"

  echo graph.kahnsAlgorithmWithScheduling(5, 60, debug)

when isMainModule:
  printAnswers("res/day7.txt", false)
