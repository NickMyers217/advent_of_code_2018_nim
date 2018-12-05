import strutils, strscans, sequtils, times, algorithm, tables

type
  ## The types of messages we can find in the logs
  MessageKind* = enum shiftBegin, fallAsleep, wakeUp

  ## A message after being parsed from the log
  Message* = object
    case kind*: MessageKind
    of shiftBegin: guardId*: int
    of fallAsleep, wakeUp: text*: string

  ## A full log entry with the date and message
  LogEntry* = object
    date*: DateTime
    message*: Message

  ## A guard is an id and an array of 60 minutes, where the values of the array
  ## are the number of days that minute was slept through
  Guard* = ref object
    id*: int
    minutes*: array[60, int]

  ## The entire sorted log of entries, and a lookup of guards by id
  Log* = ref object
    guards*: Table[int, Guard]
    entries*: seq[LogEntry]


proc initMessage*(message: string): Message =
  ## Initialize a Message from a string
  var id: int
  if message.scanf("Guard #$i begins shift", id): Message(kind: shiftBegin, guardId: id)
  elif message == "falls asleep": Message(kind: fallAsleep, text: message)
  else: Message(kind: wakeUp, text: message)

proc `$`*(message: Message): string =
  ## Render a Message as a string
  result = ""
  case message.kind
  of shiftBegin: result = "Guard #" & $message.guardId & " begins shift"
  of wakeUp, fallAsleep: result = message.text


proc newGuard*(id: int): Guard =
  ## Make a new Guard
  var arr: array[60, int]
  for i in 0..59: arr[i] = 0
  result = Guard(id: id, minutes: arr)

proc `$`*(guard: Guard): string =
  ## Render a guard as a string
  result = "id: $1 => $2" % [$guard.id, $guard.minutes]

proc getMinutesSlept*(guard: Guard): int =
  ## Get the total minutes the guard slept
  result = guard.minutes.foldl(a + b)

proc getMostSleptMinute*(guard: Guard): int =
  ## Get the minute that the guard slept the most
  result = 0
  for i in 0 .. 59:
    if guard.minutes[i] > guard.minutes[result]:
      result = i


proc initLogEntry*(entry: string): LogEntry =
  ## Initialize a log entry from a string
  var dateString, messageString: string

  if entry.scanf("[$+] $+", dateString, messageString):
    let
      date = parse(dateString, "yyyy-MM-dd HH:mm", utc())
      message = initMessage(messageString)
    result = LogEntry(date: date, message: message)
  else:
    # I really shouldn't be in here, probably should throw an exception...
    assert false


iterator walkSleeps*(log: Log, debugLog: bool = false): (int, int) =
  ## Yields every minute that a guard was sleeping in the logs
  ## in the form (guardId: int, minute: int)
  var
    guardOnDuty = 0
    startedSleepAtMinute = 0
  for entry in log.entries:
    if entry.message.kind == shiftBegin:
      guardOnDuty = entry.message.guardId
      if debugLog: echo "Guard #$1 on duty" % [$guardOnDuty]
    elif entry.message.kind == fallAsleep:
      startedSleepAtMinute = entry.date.minute
      if debugLog: echo "Guard #$1 now sleeping at $2" % [$guardOnDuty, $startedSleepAtMinute]
    else:
      let
        wokeUpAtMinute = entry.date.minute
        minutesSlept = wokeUpAtMinute - startedSleepAtMinute
      if debugLog: echo "Guard #$1 just woke up! Slept for $2 minutes from $3 - $4" % [
        $guardOnDuty, $minutesSlept, $startedSleepAtMinute, $wokeUpAtMinute
      ]
      for m in startedSleepAtMinute .. wokeUpAtMinute-1:
        yield (guardOnDuty, m)

proc newLog*(logs: seq[string]): Log =
  ## Create a new Log from the lines of the log file
  var
    entries = logs.map(initLogEntry).sorted(
      proc(a, b: LogEntry): int = (if $a.date < $b.date: -1 elif $a.date == $b.date: 0 else: 1)
    )
    log = Log(entries: entries, guards: initTable[int, Guard]())

  ## Walk all the sleeps in entries and populate the guards lookup accordingly
  for sleep in log.walkSleeps():
    let (guardId, min) = sleep
    assert min >= 0 and min < 60 # We should only be looking at minutes 0 - 59
    discard log.guards.mgetOrPut(guardId, newGuard(guardId))
    var guard: Guard = log.guards[guardId]
    guard.minutes[min] += 1

  result = log

proc findSleepiestGuard*(log: Log): Guard =
  ## Find the guard who slept the most total minutes in the log
  var mostMinutesSlept = -1
  for guard in log.guards.values():
    if guard.getMinutesSlept() > mostMinutesSlept:
      mostMinutesSlept = guard.getMinutesSlept()
      result = guard

proc getGuardMostAsleepOnMinute*(log: Log, minute: int): (Guard, int) =
  ## Locate the guard who slept the most times during `minute`, and how much he did it
  assert minute >= 0 and minute < 60

  var highestCount = -1
  for guard in log.guards.values():
    if guard.minutes[minute] > highestCount:
      highestCount = guard.minutes[minute]
      result = (guard, highestCount)

proc getMostFrequentlySleptMinute*(log: Log): (int, Guard) =
  ## Find the minute that was most frequently slept by a guard, and the guard who did it
  var mostSlept = -1
  for minute in 0 .. 59:
    let (guard, count) = log.getGuardMostAsleepOnMinute(minute)
    if count > mostSlept:
      mostSlept = count
      result = (minute, guard)


proc printAnswers*(filePath: string): void =
  ## Solve the problems and log the answers
  var log = filePath
    .readFile()
    .splitLines()
    .filter(proc(e: string): bool = e != "")
    .newLog()

  let
    guard = log.findSleepiestGuard()
    minute = guard.getMostSleptMinute()
    (minute2, guard2) = log.getMostFrequentlySleptMinute()

  echo guard.id * minute
  echo minute2 * guard2.id

when isMainModule:
  printAnswers("res/day4.txt")
