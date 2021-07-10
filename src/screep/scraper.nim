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
import nre, options, termstyle, strformat, strutils
import http
export base, xmltree, json, util, strformat, urlly, os, nre, strutils, termstyle

const 
  root = "./aberrant/"
  s_crawling* = "Crawling".negative
  s_found* = "Found".blue

let 
  default_rex = re""

# arg v_path, "out", root, help = &"output root directory, default: {root}"


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
  let node = parseHtml(res)
  if $node == "<document />":
    return nil
  else:
    return node

proc fetchJson*(url: Url, s: Session): JsonNode =
  let res = fetch($url)
  try:
    
    dbg res[0..500]
  except Exception:
    discard  
  parseJson(res)



# template pages*(r1, r2: int, pages_body: untyped) =
#   for i {.inject.} in r1..r2:
#     log &"{s_crawling} page " & $i
#     block:
#       pages_body

# template page*(id, spath: string, page_body: untyped) =
#   var urls {.inject.}: seq[string]
#   var headers {.inject.}: seq[http.Header]
#   template header(name, val: string) =
#     headers[name] = val
#   block:
#     page_body
#   urls.download getDlRoot() / id / spath, headers

# template hpage*(url: Url, id, spath: string, hpage_body: untyped) =
#   page id, spath:
#     let data {.inject.} = fetchHtml(url)
#     block:
#       hpage_body

# template jpage*(url: Url, id, spath: string, jpage_body: untyped) =
#   page id, spath:
#     let data {.inject.} = fetchJson(url)
#     block:
#       jpage_body
    
template rcase*(ms: string, body: untyped) =
  template rof(rex: Regex, match_body: untyped) =
    if ms.contains rex:
      let captures {.inject.} = ms.find(rex).get.captures.toSeq
      match_body
      break
  block:
    body
  # err &"No match found for {s}"

template scraper*(id: string, body: untyped) =
  var rex {.inject.} = default_rex
  template match(xrex: Regex) =
    rex = xrex
  template ra(name: string, def: typed = "", help = "", req = false, smod = id) =
    ra name, def, help, req, smod
  template arg(arg_name: untyped, name: string, def: typed = "", help = "", req = false, smod = id) =
    ra name, def, help, req, smod
    var `arg_name` {.inject.} = ga(name, def)
  template exec(exec_body: untyped) =
    proc get_dl_path(spath: string): string =
      return getDlRoot() / id / spath
    template pages(r1, r2: int, pages_body: untyped) =
      for i {.inject.} in r1..r2:
        log &"{s_crawling} page " & $i
        block:
          pages_body
    template page(spath: string, page_body: untyped) =
      var urls {.inject.}: seq[string]
      var headers {.inject.}: seq[http.Header]
      template header(name, val: string) =
        headers[name] = val
      block:
        page_body
      urls.download getDlRoot() / id / spath, headers
    template hpage(url: Url, spath: string, hpage_body: untyped) =
      page spath:
        let data {.inject.} = fetchHtml(url)
        if data.isNil: return
        block:
          hpage_body
    template jpage(url: Url, spath: string, jpage_body: untyped) =
      page spath:
        let data {.inject.} = fetchJson(url)
        if data.isNil: return
        block:
          jpage_body
    scrapers.add Scraper(
      name: id, 
      rex: rex,
      srun: proc (xurl {.inject.}: Url) =
        block:
          exec_body
    )
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

