import base
import os
import htmlparser
import xmltree
import nimquery
import json
import nre, options, termstyle, strformat, strutils
import http
export base, xmltree, json, strformat, os, nre, strutils, termstyle
import ark, lag, http, base, proxay, ezthread, url
export ark, lag, http, base, proxay, ezthread, url

import times
const 
  root = "./aberrant/"
  s_crawling* = "Crawling".negative
  s_found* = "Found".blue

let 
  default_rex = re""

# arg v_path, "out", root, help = &"output root directory, default: {root}"


proc `/=`*(p1: var string, p2: string) =
  # append something to a path, short for "p1 = p1 / p2"
  p1 = p1 / p2

proc empty*(url: Url): bool =
  $url == ""

proc get_root*: string =
  return root

proc get_dl_root*: string =
  return get_root() / "downloads"

proc `$`*(node: XmlNode, q: string): XmlNode = node.querySelector(q)

proc `$$`*(node: XmlNode, q: string): seq[XmlNode] = node.querySelectorAll(q)

proc fetch_html*(url: Url): XmlNode =
  let res = fetch($url)
  let node = parseHtml(res)
  if $node == "<document />":
    return nil
  else:
    return node

proc fetch_json*(url: Url, s: Session = new Session): JsonNode =
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
#   urls.download get_dl_root() / id / spath, headers

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
      return get_dl_root() / id / spath
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
      urls.download get_dl_root() / id / spath, headers
    template hpage(url: Url, spath: string, hpage_body: untyped) =
      page spath:
        let data {.inject.} = fetchHtml(url)
        block:
          hpage_body
    template jpage(url: Url, spath: string, jpage_body: untyped) =
      page spath:
        let data {.inject.} = fetchJson(url)
        block:
          jpage_body

    scrapers[id] = Scraper(
      name: id, 
      rex: rex,
      srun: proc (xurl {.inject.}: Url, args {.inject.}: ArgStore = gArgStore) {.thread.} =
        dbg args
        template get_url =
          var v_start_url {.inject.} = args.get("arg1").parseUrl
          if v_start_url.empty:
            if not xurl.empty:
              v_start_url = xurl
            else: 
              err "please provide an url"
              return
        get_url()
        block:
          exec_body
    )
  template extend(sn: string, sargs: string) =
    scrapers[id] = Scraper(
      name: id, 
      rex: rex,
      srun: proc (xurl {.inject.}: Url, args {.inject.}: ArgStore = gArgStore) {.thread.} =
        {.cast(gcsafe).}:
          let p_args: ArgStore = parse_args(sargs)
          for k,v in args:
            p_args[k] = v
          scrapers[sn].srun(xurl, p_args)
    )
  block:
    body

proc run*(scraper: Scraper, url = "") =
  log &"Using Scraper: {scraper.name}"
  let st = cpuTime()
  # var t:Thread[Url]
  # t.createThread scraper.srun, url.parseUrl
  # t.joinThread()
  scraper.srun url.parseUrl
  let ft = cpuTime() - st
  log &"Operation took {ft} seconds"