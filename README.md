## Advent of Code 2018 Nim

I have been wanting to learn Nim for a while now since it is a promising new language that does a lot of things the way I like.

The best way for me to pick up a new language is to jump right in and solve some problems, and thankfully it is December 2018 and Advent of Code is putting out a ton of cool problems to solve this month.

The problems are on the [AOC website](https://adventofcode.com/2018/).

While many people approach AOC competitively and try to solve the problems for speed, my code is optimized for different goals.
- The code is developed with TDD
- All the code is documented and readable for educational purposes
- In an effort to learn as much about the language as possible, I may choose unnecessarily long, complex, imperformant, and/or unorthodox solutions (please forgive me)
- The code attempts to be idiomatic to the Nim community's coding conventions (learning as I go)

Most of these goals are at the expense of speed.

### Dependencies
 - The Nim compiler is installed and in your path
 - The Nimble package manager is installed and in your path

### Installation
Install the above dependencies and then hop over to the shell to run:

```sh
$ git clone https://github.com/NickMyers217/advent_of_code_2018_nim
$ cd advent_of_code_2018_nim
$ nimble test
```

That will run all the unit tests for the entire project.

If you want to run the tests for a specific problem use this command and a pick a day:

```sh
$ nimble c -r tests/day1_test.nim
```

If you just want to see the answers, run the src file directly:

```sh
$ nimble c -r -d:release src/day1.nim
```
