import util
import base
import urlly
import os
import htmlparser
import xmltree
import nimquery
import puppy
import json
import urlly
import nre, options, termstyle, strformat

const 
  root = "./aberrant/"
  s_crawling* = "Crawling".negative

let default_rex* = re""

proc getRoot*: string =
  return root

proc getDlRoot*: string =
  return getRoot() / "downloads"

proc `$`*(node: XmlNode, q: string): XmlNode =
  result = node.querySelector(q)

proc `$$`*(node: XmlNode, q: string): seq[XmlNode] =
  result = node.querySelectorAll(q)

proc fetchHtml*(url: Url): XmlNode =
  let res = fetch($url)
  parseHtml(res)

proc fetchJson*(url: Url): JsonNode =
  let res = fetch($url)
  parseJson(res)


template scraper*(id: string, prex: Regex, body: untyped): untyped =
  scrapers.add Scraper(
    name: id, 
    rex: prex,
    srun: proc (xurl {.inject.}: Url) =
      let sid {.inject.} = id
      block:
        body
  )

template page*(spath: string, body: untyped) =
  var urls {.inject.}: seq[string]
  block:
    body
  urls.download getDlRoot() / sid / spath


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
    log &"{s_crawling} page " & $i
    block:
      body

import uri
proc `/`*(urls: varargs[urlly.Url]): urlly.Url =
  var base = parseUri("")
  for url in urls:
    base = base.combine(parseUri($url))
  parseUrl($base)

proc `/`*(url: urlly.Url, ext: string): urlly.Url =
  url / parseUrl(ext)

