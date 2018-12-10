import strscans, strutils, sequtils, tables, algorithm, heapqueue

type
  ## A `dependency` that must be fulfilled before `step` can be taken
  Instruction* = tuple[dependency, step: char]

  ## Statuses in a worker's workflow
  Status* = enum IDLE, BUSY, COMPLETE

  ## A worker who is accomplishing a task
  Worker* = ref object
    number: int
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

func `$`*(worker: Worker): string =
  result = "Worker " & $worker.number & ": "
  case worker.status
  of BUSY:
    result &= "[$1] Started work on $2 at $3. Will finish at $4 seconds" % [
      $worker.status,
      $worker.nodeName,
      $worker.timeStarted,
      $(worker.timeStarted + worker.duration)
    ]
  of IDLE:
    result &= "[$1] Running idle." % [ $worker.status, ]
  of COMPLETE:
    result &= "[$1] Finished work on $2 at $3!" % [
      $worker.status,
      $worker.nodeName,
      $(worker.timeStarted + worker.duration)
    ]

proc checkIfDone*(worker: var Worker, time: int) {.inline.} =
  ## Updates a worker to COMPLETE status when their task is over
  if time - worker.timeStarted >= worker.duration:
    worker.status = COMPLETE

proc assign*(worker: var Worker, nodeName: char, time, baseTaskTime: int) {.inline.} =
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
    depsMet = newHeapQueue[char]() # The nodes available to be processed

  # Find all the initially available start nodes
  for key, node in graphCopy.pairs:
    if node.isStart: depsMet.push(key)

  while depsMet.len > 0:
    var
      nodeName: char
      node: NodeValue

    nodeName = depsMet.pop()
    node = graphCopy[nodeName]
    result &= nodeName

    # Remove the edges between nodeName and its next nodes
    for key in items[char](node.nextNodes):
      graphCopy[key].prevNodes.excl(nodeName)
      # If the node has all its deps met, add it to depsMet
      if graphCopy[key].prevNodes == {}: depsMet.push(key)
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
    time = 0 # The current time in seconds
    finishTimes = newHeapQueue[int]() # Times when tasks will complete
    nodeOrder = "" # The order tasks were completed
    workers: seq[Worker] = @[]
    graphCopy = graph
    depsMet = newHeapQueue[char]() # The nodes available to be processed

  # Set up the workers
  for w in 0 ..< workerCount: workers.add(Worker(number: w))

  # Find all the initially available start nodes
  for key, node in graphCopy.pairs:
    if node.isStart: depsMet.push(key)

  proc handleWorker(w: var Worker) {.closure.} =
    ## Step a worker through his workflow
    if w.status == IDLE:
      if debug: debugEcho w
      if depsMet.len > 0:
        w.assign(depsMet.pop(), time, baseTaskTime)
        finishTimes.push(w.timeStarted + w.duration)
    if w.status == BUSY:
      if debug: debugEcho w
      w.checkIfDone(time)
    if w.status == COMPLETE:
      if debug: debugEcho w
      for key in items[char](graphCopy[w.nodeName].nextNodes):
        graphCopy[key].prevNodes.excl(w.nodeName)
        if graphCopy[key].prevNodes == {}: depsMet.push(key)
      graphCopy[w.nodeName].nextNodes = {}
      nodeOrder &= w.nodeName
      w.status = IDLE # ready to work!

  while workers.filterIt(it.status == BUSY).len > 0 or depsMet.len > 0:
    if debug: debugEcho "Time: ", time

    # Handle each worker
    for i in workers.low .. workers.high:
      handleWorker(workers[i])

    # Make sure there are no idle workers that could pick up newly created tasks,
    # sometimes the last worker frees up a bunch of stuff when the earlier ones were
    # idle with nothing to do
    while depsMet.len > 0 and workers.filterIt(it.status == IDLE).len > 0:
      for i in workers.low .. workers.high:
        if workers[i].status == IDLE: handleWorker(workers[i])

    # Step to the next time something will finish
    if finishTimes.len > 0: time = finishTimes.pop()
    else: inc time

  result = time - 1

proc printAnswers*(filePath: string, debug: bool = false) =
  let
    input = readFile(filePath)
      .splitLines()
      .filter(proc(e: string): bool = e != "")
    instructions = input.map(initInstruction)
    graph = initGraph(instructions)
    part1 = graph.kahnsAlgorithm()

  if debug:
    for key, val in graph.pairs: echo "{ ", key, ": ", val, "}"
    echo "\n============================================\n"
    for c in part1: echo "{ ", c, ": ", graph[c].nextNodes, " }"
    echo "\n============================================\n"

  let part2 = graph.kahnsAlgorithmWithScheduling(5, 60, debug)

  if debug: echo "\n============================================\n"

  echo part1
  echo part2

when isMainModule:
  printAnswers("res/day7.txt", true)
