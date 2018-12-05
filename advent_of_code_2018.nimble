# Package

version       = "0.1.0"
author        = "nickmyers217"
description   = "Answers to the Advent of Code 2018 problems in Nim"
license       = "MIT"
srcDir        = "src"
bin           = @["advent_of_code_2018"]

# Dependencies

requires "nim >= 0.18.0"


### Helper functions
proc test(name: string, defaultLang = "c") =
  if not dirExists "build":
    mkDir "build"
  --run
  switch("out", ("./build/" & name))
  setCommand defaultLang, "tests/" & name & ".nim"

### tasks
task test, "Run all tests":
  test "all_tests"
