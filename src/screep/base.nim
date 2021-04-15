import nre, urlly, options

type
  KVPair* = tuple[key, value: string]
  ScraperRun* = proc (url: Url)
  Scraper* = ref object
    name*: string
    srun*: ScraperRun
    rex*: Regex
  Scrapers* = seq[Scraper]

var scrapers*: Scrapers = @[]

proc `$`*(s: Scraper): string =
  s.name

proc `$`*(sc: Scrapers): string =
  result = "["
  for s in sc:
    result &= $s & ", "
  result = result[0..^3] & "]"

