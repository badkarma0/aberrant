import ../screep/scraper
import ../screep/util
import ../screep/jsonfs
import urlly
import re,strformat, termstyle, xmltree, os

type
  Target = ref object
    id: int
    url: Url
    level: int
  JFSRequest = ref object
    id: int
    path: string
    exists: bool

const
  s_crawling = "Crawling".style(termMagenta & termBold)
  s_skipping = "SKIPPING".style(termBold & termNegative)
  s_found_target = "Found Target".style(termItalic & termBgCyan & termBlack)
  s_failed = "FAILED".style(termBold & termRed)

var
  target_gid = 0
  exit_workers = false
  exit_jfs_worker = false
  jfs_out_channel: Channel[JFSRequest]
  jfs_in_channel: Channel[JFSRequest]
  crawl_channel: Channel[Target]

jfs_out_channel.open()
jfs_in_channel.open()
crawl_channel.open()

proc makeTarget(url: Url, level = 1): Target =
  target_gid += 1
  Target(url: url, id: target_gid, level: level)

template ez_thread(channel: Channel[untyped], msg_name: untyped, eval: untyped, body: untyped) =
  while true:
    let item = channel.tryRecv()
    if not item.dataAvailable:
      if eval:
        return
      continue
    let `msg_name` {.inject.} = item.msg
    block:
      body

proc jfs_worker {.thread.} =
  let
    r1 = re"write:"
  var 
    jfs = newJFS()

  ez_thread jfs_in_channel, request, exit_jfs_worker:
    if request.path.startsWith r1:
      logv &"[JFS] Writing to {request.path}"
      jfs.write request.path.replace(r1,"")
      logv &"[JFS] Done writing"
      return
    if jfs.has request.path:
      request.exists = true
    else:
      jfs.create request.path
      request.exists = false
    jfs_out_channel.send request

proc check_if_path_exists(path: string): bool =
  jfs_in_channel.send JFSRequest(path:path,id:getThreadId())

  ez_thread jfs_out_channel, request, false:
    if request.id == getThreadId():
      return request.exists
    else:
      jfs_out_channel.send request

proc crawl_worker {.thread.} =
  let
    v_brief = "brief".ga false 
    v_level = "level".ga 2 
    v_map = "map".ga false 
    v_path_style = "pstyle".ga 
    v_crawl_regex = "cregex".ga.re  
    v_downl_regex = "dregex".ga.re 

  while true:
    let item = crawl_channel.tryRecv()
    if not item.dataAvailable:
      if exit_workers:
        dbg "killing thread " & $getThreadId()
        return
      continue
    let target = item.msg
    let url = target.url

    if -1 == ($url).find v_crawl_regex: continue
    let ss = negative &"[LVL:{target.level}|ID:{target.id}/{target_gid}]"
    log &"{s_crawling}{ss}: {url}"

    logv &"Getting media from: {url}"
     
    var downl_urls: seq[Url] = @[]
    try:
      let data = fetchHtml(url)
      for elem in data $$ "img":
        let d_url = url / elem.attr("src")
        if check_if_path_exists(d_url.hostname & d_url.path):
          # dbg &"{s_skipping} {d_url}"
          continue
        # dbg "found new" & $d_url
        downl_urls.add(d_url)
      for elem in data $$ "a":
        let c_url = url / elem.attr("href")
        if check_if_path_exists(c_url.hostname & c_url.path): 
          # dbg &"{s_skipping} {c_url}"
          continue
        # dbg &"{s_found_target}: {c_url}"
        # dbg "found new" & $c_url
        if v_level > target.level:
          crawl_channel.send c_url.makeTarget(target.level + 1)
    except Exception:
      err &"{s_crawling} {url} {s_failed}"

    if target.level == 1:
      exit_workers = true

    if v_brief:
      log &"Found {downl_urls.len} downloads in {url}"
      continue

    if v_map: continue
    
    for downl_url in downl_urls:
      if -1 == ($downl_url).find v_downl_regex: continue

      var path = getDlRoot() / "mcrawl"
      case v_path_style:
      of "compact", "c":
        path /= downl_url.path.extractFilename
      of "real", "r":
        path /= downl_url.hostname / downl_url.path
      of "":
        path /= downl_url.hostname / downl_url.path.extractFilename


      let dl = makeDownload($downl_url, path)
      dl.download

scraper "mcrawl":
  arg v_start_url, "arg1", req = true, help = "an url"
  ra "brief", false, help = "less logging for downloads"
  ra "level", 2, help = "how many times to recurse into starting url"
  ra "pstyle", help = "path style: can be one of [compact/c, real/r]"
  ra "dregex"
  ra "cregex"
  arg v_map, "map", false, help = "create a site map, no downloads"
  exec:
    if v_start_url == "":
      if not xurl.empty:
        v_start_url = $xurl
      else: 
        err "please provide an url"
        return
    
    crawl_channel.send parseUrl(v_start_url).makeTarget

    var jfs_thread: Thread[void]
    jfs_thread.createThread jfs_worker

    const v_threads = 10
    var threads: array[v_threads, Thread[void]]
    for i in 0..v_threads-1:
      threads[i].createThread crawl_worker
    
    joinThreads(threads)

    if v_map:
      let map_path = getRoot() / "mcrawl_maps" / parseUrl(v_start_url).hostname & ".json"
      map_path.parentDir.createDir
      jfs_in_channel.send(JFSRequest(id: getThreadId(), path: "write:" & map_path))

    exit_jfs_worker = true

    joinThread(jfs_thread)
