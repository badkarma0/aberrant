import nre
import strutils
import sequtils

let 
  r1 = re"\{.*?\}"
  r2 = re"\{|\}"
# reverse regular expression
proc generate*(templates: seq[string]): seq[string] =
  var incomplete: seq[string]  
  for temp in templates:
    for match in temp.findIter r1:
      let parts = match.match.replace(r2, "").split(",")
      let l = parts.len
      var 
        start = 1
        vend = 10
        inc = 1
      if l > 0:
        start = parts[0].parseInt
      if l > 1:
        vend = parts[1].parseInt
      if l > 2:
        inc = parts[2].parseInt
      if start > vend: continue
      var i = start
      while i < vend:
        let s = temp[0..(match.matchBounds.a - 1)] & $i & temp[(match.matchBounds.b + 1)..^1]
        if s.find(r2).isSome:
          incomplete.add s
        else:
          result.add s
        i += inc
  if incomplete.len > 0:
    result = result.concat generate(incomplete)    

when isMainModule:
  echo generate(@["xxx{1,10,2}.jpg","https://x.org/img/aw{1,10,2}{1,10,2}.jpg"])