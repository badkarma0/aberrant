import os
import urlly, strutils, termstyle

import ark, lag, http, base, proxay
export ark, lag, http, base, proxay

# MISC

proc `/=`*(p1: var string, p2: string) =
  # append something to a path, short for "p1 = p1 / p2"
  p1 = p1 / p2

proc empty*(url: Url): bool =
  $url == ""

proc row(s: string, ch = '+', color = termWhite): string =
  for c in 0..s.len + 1:
    result.add(ch)
  result.style(color)

proc col(s: string, ch = '+', cc = termWhite, sc = termWhite): string =
  result.add(cc)
  result.add("\n" & ch)
  result.add(termClear & sc)
  result.add(s)
  result.add(termClear & cc)
  result.add(ch)
  result.add(termClear)

proc box(s: string, ch = '+', cc = termWhite, sc = termWhite): string =
  result.add s.row(ch, cc)
  for spart in s.split("\n"):
    result.add spart.col(ch, cc, sc)
  result.add('\n')
  result.add s.row(ch, cc)




