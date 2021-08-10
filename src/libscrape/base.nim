import nre, options
import tables, strformat
export tables
import os
import sparse
import url
type
  KVPair* = ref object 
    key*, value*: string
  ScraperRun* = proc (url: Url) {.thread.}
  Scraper* = ref object
    name*: string
    srun*: ScraperRun
    rex*: Regex
  Scrapers* = Table[string, Scraper]


const version* = block:
  var b = slurp("../../aberrant.nimble")
  var i = 0
  var t = b.next_token(i)
  while "version" != t:
    t = b.next_token(i)
  discard b.next_token(i)
  "Aberrant v" & b.next_token(i)[1..^2]


var scrapers*: Scrapers

proc `$`*(s: Scraper): string =
  s.name

proc `$`*(sc: Scrapers): string =
  result = "["
  for s in sc.values:
    result &= $s & ", "
  result = result[0..^3] & "]"


proc wait* =
  while true:
    sleep 1000