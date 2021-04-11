import termstyle

type
  KVPair* = tuple[key, value: string]
  ScraperRun* = proc (args: varargs[KVPair])
  Scraper* = ref object
    name*: string
    srun*: ScraperRun
  Scrapers* = seq[Scraper]

var scrapers*: Scrapers = @[]

proc `$`*(s: Scraper): string =
  s.name

proc `$`*(sc: Scrapers): string =
  result = "["
  for s in sc:
    result &= $s & ", "
  result = result[0..^3] & "]"

