
const whitepsace = [" ", "\r", "\n", "\t"]

proc skip_whitespace*(s:string, i: var int) =
  while whitepsace.contains($s[i]):
    inc i

proc next_token*(s: string, i: var int):string =
  s.skip_whitespace(i)
  while not whitepsace.contains($s[i]):
    result &= $s[i]
    inc i
    