import nre, urlly, options
import tables
export tables
type
  KVPair* = ref object 
    key*, value*: string
  ScraperRun* = proc (url: Url) {.thread.}
  Scraper* = ref object
    name*: string
    srun*: ScraperRun
    rex*: Regex
  Scrapers* = Table[string, Scraper]

var scrapers*: Scrapers

proc `$`*(s: Scraper): string =
  s.name

proc `$`*(sc: Scrapers): string =
  result = "["
  for s in sc.values:
    result &= $s & ", "
  result = result[0..^3] & "]"

import uri
proc `/`*(urls: varargs[urlly.Url]): urlly.Url =
  var base = parseUri("")
  for url in urls:
    base = base.combine(parseUri($url))
  parseUrl($base)

proc `/`*(url: urlly.Url, ext: string): urlly.Url =
  url / parseUrl(ext)

