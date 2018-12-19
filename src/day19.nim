import strutils, sequtils, tables, strscans, sets

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

proc parseProgram(input: string): Program =
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

proc sumOfDivisors(n: int): int =
  ## Brute force calculation for the sum of all factors of n
  result = 0
  for d in 1 .. n:
    if n mod d == 0: inc result, d

proc execute(program: Program, registers: var Registers) =
  ## Executes `program` on the given `registers`
  let (ipRegister, instructions) = program
  var ip = 0

  while ip >= instructions.low and ip <= instructions.high:
    registers[ipRegister] = ip
    instructions[ip].execute(registers)
    ## NOTE:
    ## The program only hits an instruction pointer of 1 a SINGLE time
    ## the number in the final register is of signficance here
    ## for part 1 the number in the fith register was 1017, and after completing
    ## the program, 1482 was in register 0. 1482 is the sum of all of 1017's
    ## divisors!
    ##
    ## Extrapolating that out for part two, 10551417 is the number in register 5
    ## and the sum of all of its divisors is 14068560
    if ip == 1:
      echo instructions[ip], " on ", registers, " => ", registers[ipRegister]
      registers[0] = sumOfDivisors(registers[5])
      return
    ip = registers[ipRegister] + 1

proc printAnswers(input: string) =
  let program = parseProgram(input)

  var registers: Registers = [ 0, 0, 0, 0, 0, 0 ]
  program.execute(registers)

  var moreRegisters: Registers = [ 1, 0, 0, 0, 0, 0 ]
  program.execute(moreRegisters)

  echo registers[0]
  echo moreRegisters[0]

when isMainModule:
  let input = readFile("./res/day19.txt")
  let testInput = """
#ip 0
seti 5 0 1
seti 6 0 2
addi 0 1 0
addr 1 2 3
setr 1 0 0
seti 8 0 4
seti 9 0 5"""

  printAnswers(input)
