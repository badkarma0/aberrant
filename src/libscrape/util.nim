import times, macros, macroutils, sugar

func `or`*(a,b: string): string = 
  if a == "": b else: a

template time*(s: string, b) =
  let st = cpuTime()
  block: b
  let ft = cpuTime() - st
  echo s & " took " & $ft

# macro rtime*(p) =
#   p.forNode(nnkCall, (c) => Call(Ident"time", StrLit"c", c))
#   echo p.treeRepr