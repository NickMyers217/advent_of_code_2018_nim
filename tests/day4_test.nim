import unittest, times, sequtils, tables

import ../src/day4

const testData = @[
  "[1518-11-01 00:00] Guard #10 begins shift",
  "[1518-11-01 00:05] falls asleep",
  "[1518-11-01 00:25] wakes up",
  "[1518-11-01 00:30] falls asleep",
  "[1518-11-01 00:55] wakes up",
  "[1518-11-01 23:58] Guard #99 begins shift",
  "[1518-11-02 00:40] falls asleep",
  "[1518-11-02 00:50] wakes up",
  "[1518-11-03 00:05] Guard #10 begins shift",
  "[1518-11-03 00:24] falls asleep",
  "[1518-11-03 00:29] wakes up",
  "[1518-11-04 00:02] Guard #99 begins shift",
  "[1518-11-04 00:36] falls asleep",
  "[1518-11-04 00:46] wakes up",
  "[1518-11-05 00:03] Guard #99 begins shift",
  "[1518-11-05 00:45] falls asleep",
  "[1518-11-05 00:55] wakes up"
]

suite "Day 4 tests":
  test "Can parse a LogEntry":
    let entries = testData.map(initLogEntry)
    check:
      entries[0].date.year == 1518
      entries[0].date.month == mNov
      entries[0].date.monthday == 01
      entries[0].date.hour == 0
      entries[0].date.minute == 0
      entries[0].date.second == 0
      entries[0].message.kind == shiftBegin
      entries[0].message.guardId == 10
      entries[1].message.kind == fallAsleep
      entries[1].message.text == "falls asleep"
      entries[2].message.kind == wakeUp
      entries[2].message.text == "wakes up"

  test "Can parse a Log":
    let log = newLog(testData)
    check(log.entries.len() == 17)

    for i in 0 .. log.entries.len() - 2:
      check($log.entries[i] < $log.entries[int(i) + 1])

    check:
      log.guards.len() == 2
      log.guards.hasKey(10)
      log.guards.hasKey(99)
      log.guards[10].minutes == [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0]
      log.guards[99].minutes == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0]

  test "Can find how many total minutes a guard slept":
    let log = newLog(testData)
    check:
      log.guards[10].getMinutesSlept() == 50
      log.guards[99].getMinutesSlept() == 30

  test "Can find the guard who slept the most total minutes":
    let guard: Guard = newLog(testData).findSleepiestGuard()
    check(guard.id == 10)

  test "Can find the most slept minute a guard had":
    let guard: Guard = newLog(testData).findSleepiestGuard()
    check(guard.getMostSleptMinute() == 24)

  test "Can get the id of the sleepiest guard times his most slept minute":
    let
      guard = newLog(testData).findSleepiestGuard()
      minute = guard.getMostSleptMinute()
    check(guard.id * minute == 240)

  test "Can find the guard who is most frequently asleep on a given minute":
    let (guard, count) = newLog(testData).getGuardMostAsleepOnMinute(45)
    check(guard.id == 99)
    check(count == 3)

  test "Can find the minute that was most frequently slept by a guard":
    let (minute, guard) = newLog(testData).getMostFrequentlySleptMinute()
    check:
      minute == 45
      guard.id == 99
      minute * guard.id == 4455
