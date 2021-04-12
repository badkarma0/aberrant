import ../screep/scraper
import ../screep/util
import urlly
import re,strformat, termstyle, xmltree, os

type
  Target = ref object
    url: Url

const
  s_crawling = "Crawling".style(termMagenta & termBold)

var
  exit_workers = false
  crawl_channel: Channel[Target]

crawl_channel.open()

proc crawl_worker {.thread.} =
  let
    v_dry = ga("d", false)
    v_path_style = ga("pstyle")
    v_crawl_regex = ga("cregex").re
    v_downl_regex = ga("dregex").re

  while true:
    let item = crawl_channel.tryRecv()
    if not item.dataAvailable:
      if exit_workers:
        dbg "killing thread"
        break
      continue

    let target = item.msg
    let url = target.url

    if -1 == ($url).find v_crawl_regex: continue

    log &"{s_crawling}: {url}"

    logv &"Getting media from: {url}"
    
    var downl_urls: seq[Url] = @[]
    try:
      let data = fetchHtml(url)
      for elem in data $$ "img":
        downl_urls.add(url / elem.attr("src"))
      for elem in data $$ "a":
        crawl_channel.send(Target(url: url / elem.attr("href")))
    except Exception:
      err &"{s_crawling} {url} failed"

    for downl_url in downl_urls:
      if -1 == ($downl_url).find v_downl_regex: continue

      var path = getRoot() / "mcrawl"
      case v_path_style:
      of "compact", "c":
        path /= downl_url.path.extractFilename
      of "real", "r":
        path /= downl_url.hostname / downl_url.path
      of "":
        path /= downl_url.hostname / downl_url.path.extractFilename

      path.parentDir.createDir

      let dl = makeDownload($downl_url, path)
      if v_dry:
        log &"Found {dl}"
      else:
        dl.download

    

scraper "mcrawl":
  let v_start_url = ga("arg1")
  if v_start_url == "":
    err "please provide an url"
    return
  
  crawl_channel.send(Target(url: parseUrl(v_start_url)))

  let v_threads = ga("threads", 10)
  var threads: array[10, Thread[void]]

  for i in 0..9:
    threads[i].createThread crawl_worker
  # exit_workers = true
  joinThreads(threads)
