import util
import base
import urlly
import os
import htmlparser
import xmltree
import nimquery
import puppy
import uri
import json
import urlly

const root = "./aberrant/downloads/"

proc `$`*(node: XmlNode, q: string): XmlNode =
  result = node.querySelector(q)

proc `$$`*(node: XmlNode, q: string): seq[XmlNode] =
  result = node.querySelectorAll(q)

proc fetchHtml*(url: urlly.Url): XmlNode =
  let res = fetch($url)
  parseHtml(res)

proc fetchJson*(url: urlly.Url): JsonNode =
  let res = fetch($url)
  parseJson(res)

proc `/`*(url: urlly.Url, ext: string): urlly.Url =
  parseUrl($(parseUri($url) / ext))

template scraper*(id: string, body: untyped) =
  scrapers.add Scraper(
    name: id, 
    srun: proc () =
      let sid {.inject.} = id
      block:
        body
  )

template page*(spath: string, body: untyped) =
  var urls {.inject.}: seq[string]
  block:
    body
  urls.download root / sid / spath


template hpage*(url: urlly.Url, spath: string, body: untyped) =
  page spath:
    let data {.inject.} = fetchHtml(url)
    block:
      body

template jpage*(url: urlly.Url, spath: string, body: untyped) =
  page spath:
    let data {.inject.} = fetchJson(url)
    block:
      body
    
template pages*(r1, r2: int, body: untyped) =
  for i {.inject.} in r1..r2:
    echo "scraping page " & $i
    block:
      body

