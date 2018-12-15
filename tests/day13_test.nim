import unittest

import ../src/day13


const partOneInput = """
/->-\        
|   |  /----\
| /-+--+-\  |
| | |  | v  |
\-+-/  \-+--/
  \------/   
"""

const partTwoInput = """
/>-<\  
|   |  
| /<+-\
| | | v
\>+</ |
  |   ^
  \<->/
"""

suite "Day 13 Tests":
  test "Can find the location of the first collision":
    check findFirstCollision(partOneInput) == (7,3)

  test "Can find the location of the last cart":
    check findLastCart(partTwoInput) == (6,4)

