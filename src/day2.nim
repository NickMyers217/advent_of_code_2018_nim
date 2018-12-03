import tables, sequtils, strutils

proc hasLetterCount*(id: string, count: int): bool =
  ## Determine if a string has at least one char that appears `count` times
  result = false
  for n in id.toCountTable().values():
    if n == count:
      return true

proc getChecksum*(data: seq[string]): int =
  ## Caclulate the checksum for `data`
  let twoCount = data.filter(proc(e: string): bool = e.hasLetterCount(2)).len
  let threeCount = data.filter(proc(e: string): bool = e.hasLetterCount(3)).len
  twoCount * threeCount

proc getTargetBoxLetters*(data: seq[string]): string =
  ## Get the letters that the 2 correct boxes have in common
  result = ""
  for idOne in data:
    for idTwo in data:
      # Dont bother if the strings are identical or invalid
      if idOne == idTwo or idOne == "" or idTwo == "":
        continue

      # This algorithm wont work if these are not the same length
      assert idOne.len() == idTwo.len()

      var
        lettersDifferent = 0
        indexDifferentAt = 0

      for i in idOne.low() .. idOne.high():
        if idOne[i] != idTwo[i]:
          lettersDifferent += 1
          indexDifferentAt = i

        if lettersDifferent > 1:
          break

      if lettersDifferent != 1:
        continue
      else:
        return idOne[idOne.low() .. indexDifferentAt - 1] & idOne[indexDifferentAt + 1 .. idOne.high()]

proc getPartOneAnswer*(filePath: string): int =
  ## Get the answer for the first part
  filePath
    .readFile()
    .splitLines()
    .getChecksum()

proc getPartTwoAnswer*(filePath: string): string =
  ## Get the answer for the second part
  filePath
    .readFile()
    .splitLines()
    .getTargetBoxLetters()

