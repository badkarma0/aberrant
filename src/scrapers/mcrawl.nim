import ../libscrape
import xmltree, nre

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
  total_downloads = 0
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
    if request.path.startsWith "write:":
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

proc crawl_worker(args: ArgStore) {.thread.} =
  let
    v_brief = args.get("brief", false) 
    v_level = args.get("level", 2) 
    v_map = args.get("map", false) 
    v_path_style = args.get("pstyle")
    v_crawl_regex = args.get("cregex").re 
    v_downl_regex = args.get("dregex").re
    v_cm = args.get("cm", 0)
    v_dm = args.get("dm", 0)
    v_cml = args.get("cml", 0)
    v_dml = args.get("dml", 0)
    v_autoref = args.get("autoref", true)
  lag_add_thread()
  while true:
    let item = crawl_channel.tryRecv()
    if not item.dataAvailable:
      if exit_workers:
        dbg "killing thread " & $getThreadId()
        lag_del_thread()
        return
      continue
    let target = item.msg
    let url: Url = target.url

    if not ($url).contains v_crawl_regex: continue
    let ss = negative &"[LVL:{target.level}|ID:{target.id}/{target_gid}]"
    log &"{s_crawling}{ss}: {url}"

    logv &"Getting media from: {url}"
     
    var downl_urls: seq[Url] = @[]
    var crawl_counter = 0
    try:
      let data = fetchHtml(url)
      # dbg data.rawText[0..200]
      for elem in data $$ "img, video, source":
        let d_url = url.combine elem.attr("src").parseUrl
        if check_if_path_exists(d_url.hostname & d_url.path):
          # dbg &"{s_skipping} {d_url}"
          continue
        # dbg "found new" & $d_url
        downl_urls.add(d_url)
        total_downloads += 1
        if v_dm != 0 and total_downloads >= v_dm: break
      for elem in data $$ "a":
        let c_url = url / elem.attr("href")
        if check_if_path_exists(c_url.hostname & c_url.path): 
          # dbg &"{s_skipping} {c_url}"
          continue
        # dbg &"{s_found_target}: {c_url}"
        # dbg "found new" & $c_url
        if v_level > target.level:
          crawl_channel.send c_url.makeTarget(target.level + 1)
        if target_gid >= v_cm: break
    except Exception:
      err &"{s_crawling} {url} {s_failed}"

    if target.level == 1:
      exit_workers = true

    if v_brief:
      log &"Found {downl_urls.len} downloads in {url}"
      continue

    if v_map: continue
    
    for downl_url in downl_urls:
      if not ($downl_url).contains v_downl_regex: continue

      var path = getDlRoot() / "mcrawl"
      case v_path_style:
      of "compact", "c":
        path /= downl_url.path.extractFilename
      of "real", "r":
        path /= downl_url.hostname / downl_url.path
      of "":
        path /= downl_url.hostname / downl_url.path.extractFilename

      let dl = make_download($downl_url, path)
      if v_autoref:
        dl.headers["referer"] = $url
      dl.download

scraper "mcrawl":
  ra "arg1", req = true, help = "an url"
  ra "brief", false, help = "less logging for downloads"
  ra "level", 2, help = "how many times to recurse into starting url"
  ra "pstyle", help = "path style: can be one of [compact/c, real/r]"
  ra "dregex"
  ra "cregex"
  ra "map", false, help = "create a site map, no downloads"
  ra "cm", 0, help = "maximum links to crawl"
  ra "cml", 0, help = "maximum links to crawl per level"
  ra "dm", 0, help = "maximum links to download"
  ra "dml", 0, help = "maximum links to download per level"
  exec:
    var 
      v_start_url = args.get("arg1").parseUrl
      v_map = args.get("map", false)
    if v_start_url.empty:
      if not xurl.empty:
        v_start_url = xurl
      else: 
        err "please provide an url"
        return
    
    crawl_channel.send v_start_url.makeTarget

    var jfs_thread: Thread[void]
    jfs_thread.createThread jfs_worker

    const v_threads = 10
    var threads: array[v_threads, Thread[ArgStore]]
    for i in 0..v_threads-1:
      threads[i].createThread crawl_worker, args
    
    joinThreads(threads)

    if v_map:
      let map_path = getRoot() / "mcrawl_maps" / v_start_url.hostname & ".json"
      map_path.parentDir.createDir
      jfs_in_channel.send(JFSRequest(id: getThreadId(), path: "write:" & map_path))

    exit_jfs_worker = true

    joinThread(jfs_thread)
