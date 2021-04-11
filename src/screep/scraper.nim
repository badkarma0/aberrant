import util
import base
import urlly
import os

const root = "./aberrant/downloads/"

template scraper*(id: string, body: untyped) =
  scrapers.add Scraper(
    name: id, 
    srun: proc (args: varargs[KVPair]) =
      let va = @args
      let sid {.inject.} = id
      proc v(name: string, def = ""): string {.inject.} =
        for arg in va:
          if arg.key == name:
            return arg.value
        return def
      block:
        body
  )

template page*(spath: string, body: untyped) =
  var urls {.inject.}: seq[string]
  block:
    body
  urls.download root / sid / spath


template hpage*(url: Url, spath: string, body: untyped) =
  page spath:
    let data {.inject.} = fetchHtml(url)
    block:
      body

template jpage*(url: Url, spath: string, body: untyped) =
  page spath:
    let data {.inject.} = fetchJson(url)
    block:
      body
    
template pages*(r1, r2: int, body: untyped) =
  for i {.inject.} in r1..r2:
    echo "scraping page " & $i
    block:
      body
