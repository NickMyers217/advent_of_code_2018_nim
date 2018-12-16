import strutils, sequtils, tables, strscans, sets

const NUM_REGISTERS = 4
const NUM_OPCODES = 16

type
  ## Convenience for an array of regisers
  Registers* = array[NUM_REGISTERS, int]
  ## All the different operations
  Op* = enum
    Addr, Addi,
    Mulr, Muli,
    Banr, Bani,
    Borr, Bori,
    Setr, Seti,
    Gtir, Gtri, Gtrr,
    Eqir, Eqri, Eqrr
  ## An instruction
  Instruction* = tuple[op: Op, a, b, c: int]
  ## A test case for an instruction
  InstructionTest* = tuple
    before: Registers
    ins: Instruction
    after: Registers
  ## A mapping of ops to their codes
  OpMapping* = array[NUM_OPCODES, Op]

proc parseInstructionTest(lines: seq[string]): InstructionTest =
  ## Parses a before state, an instruction, and an after state
  assert lines.len == 3
  var
    ins: Instruction
    before, after: Registers
    b0, b1, b2, b3, i0, i1, i2, i3, a0, a1, a2, a3: int
  if lines[0].scanf("Before: [$i, $i, $i, $i]", b0, b1, b2, b3):
    before = [b0, b1, b2, b3]
  else:
    echo "Error parsing Before!"
    assert false
  if lines[1].scanf("$i $i $i $i", i0, i1, i2, i3):
    ins = (op: Op(i0), a: i1, b: i2, c: i3)
  else:
    echo "Error parsing Instruction!"
    assert false
  if lines[2].scanf("After:  [$i, $i, $i, $i]", a0, a1, a2, a3):
    after = [a0, a1, a2, a3]
  else:
    echo "Error parsing After!"
    assert false
  result = (before, ins, after)

proc parseTests(input: string): seq[InstructionTest] =
  ## Parse all the test cases from the input
  var lines = input.splitLines().filterIt(it != "")
  result = lines.distribute(int(lines.len / 3)).mapIt(parseInstructionTest(it))

proc parseInstruction(input: string, mapping: OpMapping): Instruction =
  ## Parse an individual instruction with his correctly mapped op code
  var i0, i1, i2, i3: int
  if input.scanf("$i $i $i $i", i0, i1, i2, i3):
    result = (op: mapping[i0], a: i1, b: i2, c: i3)
  else:
    echo "Error parsing Instruction!"
    assert false

proc parseProgram(input: string, mapping: OpMapping): seq[Instruction] =
  ## Parse a whole program using the givin op code mapping
  result = input
    .splitLines()
    .filterIt(it != "")
    .mapIt(it.parseInstruction(mapping))

proc execute*(instruction: Instruction, registers: var Registers) =
  ## Executes `instruction` on `registers`
  let (op, a, b, c) = instruction
  case op
  of Addr: registers[c] = registers[a] + registers[b]
  of Addi: registers[c] = registers[a] + b
  of Mulr: registers[c] = registers[a] * registers[b]
  of Muli: registers[c] = registers[a] * b
  of Banr: registers[c] = registers[a] and registers[b]
  of Bani: registers[c] = registers[a] and b
  of Borr: registers[c] = registers[a] or registers[b]
  of Bori: registers[c] = registers[a] or b
  of Setr: registers[c] = registers[a]
  of Seti: registers[c] = a
  of Gtir: registers[c] = if a > registers[b]: 1 else: 0
  of Gtri: registers[c] = if registers[a] > b: 1 else: 0
  of Gtrr: registers[c] = if registers[a] > registers[b]: 1 else: 0
  of Eqir: registers[c] = if a == registers[b]: 1 else: 0
  of Eqri: registers[c] = if registers[a] == b: 1 else: 0
  of Eqrr: registers[c] = if registers[a] == registers[b]: 1 else: 0

proc execute*(program: seq[Instruction]): Registers =
  ## Execute a whole program
  result = [0, 0, 0, 0]
  for ins in program:
    ins.execute(result)

proc testAllOps*(test: InstructionTest): seq[Op] =
  ## Find all of the ops that could fit the op code for `instruction`
  ## becuase they produce the register state in `after` from `before`
  result = newSeq[Op]()
  let
    (before, ins, after) = test
    (_, a, b, c) = ins
  for op in Op.low .. Op.high:
    let insCopy = (op: op, a: a, b: b, c: c)
    var regCopy = before
    insCopy.execute(regCopy)
    if regCopy == after:
      result.add(op)

proc printAnswers(inputOne, inputTwo: string) =
  let
    tests = inputOne.parseTests()
    possibleOps = tests.mapIt(testAllOps(it))

  ### Part 1
  echo possibleOps.filterIt(it.len >= 3).len

  ### Part 2
  # To figure out the op codes we just need to start by looking
  # for test cases that matched only one op code. We now know what
  # instruction that op code is for, and it to the set of knownOps.
  # Now we continue to look for cases that have only one match
  # after excluding the known ops, etc..
  var
    ops: OpMapping
    knownOps = initSet[Op]()
  while knownOps.len < NUM_OPCODES:
    for i in tests.low .. tests.high:
      var
        possibleOps = possibleOps[i]
        opsNotKnown = possibleOps.filterIt(it notin knownOps)
      if opsNotKnown.len == 1:
        var op = tests[i].ins.op
        ops[ord(op)] = opsNotKnown[0]
        knownOps.incl(opsNotKnown[0])
  let program = inputTwo.parseProgram(ops)
  echo program.execute()[0]

when isMainModule:
  printAnswers(readFile("res/day16_part1.txt"), readFile("res/day16_part2.txt"))
