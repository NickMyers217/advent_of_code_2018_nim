import strutils, sequtils, tables, strscans, intsets

const NUM_REGISTERS = 6

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
  ## A program to execute
  Program = tuple[ipRegister: int, instructions: seq[Instruction]]

proc parseOp(opStr: string): Op =
  ## Parse an op from a string
  case opStr
  of "addr": result = Addr
  of "addi": result = Addi
  of "mulr": result = Mulr
  of "muli": result = Muli
  of "banr": result = Banr
  of "bani": result = Bani
  of "borr": result = Borr
  of "bori": result = Bori
  of "setr": result = Setr
  of "seti": result = Seti
  of "gtir": result = Gtir
  of "gtri": result = Gtri
  of "gtrr": result = Gtrr
  of "eqir": result = Eqir
  of "eqri": result = Eqri
  of "eqrr": result = Eqrr

proc `$`(ins: Instruction): string {.inline.} = "$1 $2 $3 $4" % [$ins.op, $ins.a, $ins.b, $ins.c]

proc parseInstruction(input: string): Instruction =
  ## Parse an individual instruction
  var
    opStr: string
    a, b, c: int
  if input.scanf("$w $i $i $i", opStr, a, b, c):
    result = (parseOp opStr, a, b, c)
  else:
    echo "Error parsing Instruction!"
    assert false

proc parseProgram*(input: string): Program =
  ## Parse a whole program and return the IP register and the instructions
  let lines = input.splitLines().filterIt(it != "")
  var ip: int
  discard lines[0].scanf("#ip $i", ip)
  result = (ip, lines[1..^1].mapIt(parseInstruction it))

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

proc execute*(program: Program, registers: var Registers) =
  ## Executes `program` on the given `registers`
  let (ipRegister, instructions) = program
  var ip = 0
  while ip >= instructions.low and ip <= instructions.high:
    registers[ipRegister] = ip
    instructions[ip].execute(registers)
    ip = registers[ipRegister] + 1

proc findFastestTermination*(program: Program, registers: var Registers): int =
  ## Executes `program` on the given `registers`, and returns the starting value
  ## for register zero that would terminate the program with the least instructions
  let (ipRegister, instructions) = program
  var ip = 0
  while ip >= instructions.low and ip <= instructions.high:
    registers[ipRegister] = ip
    if instructions[ip].op == Eqrr:
      result =
        if instructions[ip].a == 0: registers[instructions[ip].b]
        else: registers[instructions[ip].a]
      return
    instructions[ip].execute(registers)
    ip = registers[ipRegister] + 1

proc findLowestTermination*(program: Program, registers: var Registers): int =
  ## Executes `program` on the given `registers`, and returns the lowest starting
  ## value for register zero that causes the most instructions
  let (ipRegister, instructions) = program
  var
    # We are looping forever and need to keep track of all the terminations
    # so we can break at the beginning of the 2nd cycle
    terminations = initIntSet()
    ip = 0
  while ip >= instructions.low and ip <= instructions.high:
    registers[ipRegister] = ip
    if instructions[ip].op == Eqrr:
      let terminatingVal =
        if instructions[ip].a == 0: registers[instructions[ip].b]
        else: registers[instructions[ip].a]
      if terminations.containsOrIncl(terminatingVal):
        # The cycle just restarted so we can break
        return
      else:
        result = terminatingVal
    instructions[ip].execute(registers)
    ip = registers[ipRegister] + 1

proc printAnswers(input: string) =
  let program = parseProgram(input)

  block part1:
    var registers: Registers = [ 0, 0, 0, 0, 0, 0 ]
    echo program.findFastestTermination(registers)

  block part2:
    var registers: Registers = [ 0, 0, 0, 0, 0, 0 ]
    echo program.findLowestTermination(registers)

when isMainModule:
  let input = readFile("./res/day21.txt")
  printAnswers(input)
