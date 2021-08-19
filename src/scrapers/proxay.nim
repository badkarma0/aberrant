


let
  g_sources = [
    "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=socks4&timeout=10000&country=all",
    "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=socks5&timeout=10000&country=all",
    "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all",
    "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=https&timeout=10000&country=all",
    "https://proxy-daily.com/",
    "http://proxysearcher.sourceforge.net/Proxy%20List.php?type=socks",
    "http://proxysearcher.sourceforge.net/Proxy%20List.php?type=http",
    "http://free-proxy-list.net/anonymous-proxy.html",
    "https://free-proxy-list.net/",
    "https://www.socks-proxy.net/",
    "http://sslproxies24.blogspot.in/feeds/posts/default",
    "http://vipaccounts24.blogspot.com/feeds/posts/default",
    "http://rootjazz.com/proxies/proxies.txt",
    "http://proxyape.com/",
    "http://highbroadcast-proxy.blogspot.com/feeds/posts/default",
    "http://socksproxylist24.blogspot.com/feeds/posts/default",
    "http://proxyandproxytools.blogspot.com/feeds/posts/default",
    "http://free-fresh-proxy-daily.blogspot.com/feeds/posts/default",
    "http://www.live-socks.net/feeds/posts/default",
    "http://www.socks24.org/feeds/posts/default",
    "http://www.megaproxylist.net/",
    "http://getfreeproxylists.blogspot.com/",
    "https://www.sslproxies.org/",
    "http://proxiatyomia.blogspot.com/feeds/posts/default",
    "http://www.proxyserverlist24.top/feeds/posts/default",
  ]

import ../libscrape
import sets, re, asyncdispatch, httpclient, sequtils

type 
  Counter = ref object
    fail,succ,done,total,http,https,socks4,socks5,working: int
  Udata = (ArgStore, Counter, ptr Channel[string], ptr Channel[string])
const 
  azenv = "http://azenv.net"
  g_protocols = ["http", "https", "socks4", "socks5"]

let
  r_ip_port = re"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5}"
  r_xml_tag = re"<[^>]*>"

proc process_page(url: string): Future[HashSet[string]] {.async.} =
  var client = newAsyncHttpClient()
  log "get", url
  var data = ""
  try:
    data = await client.getContent(url)
  except Exception:
    discard
  # data = data.replace(r_xml_tag, "")
  for m in data.findAll(r_ip_port):
    result.incl m
  log "found", result.len, "proxies"

proc process_pages(): Future[HashSet[string]] {.async.} =
  var ts: seq[Future[HashSet[string]]]
  for source in g_sources:
    ts.add process_page(source)  
  for f in ts:
    result.incl await f

proc process_pages_sequential(max: int, sources: seq[string]
): Future[HashSet[string]] {.async.} =
  for source in sources:
    let proxies = await process_page(source)
    result.incl proxies
    if max != 0 and result.len > max:
      var nset: HashSet[string]
      for _ in 0..max-1:
        nset.incl result.pop
      return nset

proc proxay_worker(udata: Udata) {.async.} =
  var 
    channel = udata[2]
    args = udata[0]
    counter = udata[1]
    write_channel = udata[3]
    # protocols = args.get("protocols", g_protocols)
    protocols = g_protocols
    working = args.get("working", 0)
    f = true
  while true:
    let pek = channel[].peek()
    if pek < 1: break
    let message = channel[].recv() 
    var fails = 0
    for prot in protocols:
      let prox = prot & "://" & message
      var ok = false
      logv prox
      try:
        ok = await std_proxy_check(azenv, prox)
      except Exception:
        ok = false
      if ok:
        log "OK", prox
        inc counter.working
        if working != 0 and counter.working >= working: return
        write_channel[].send(prox)
        if prot == "http":
          inc counter.http
        if prot == "https":
          inc counter.https
        if prot == "socks4":
          inc counter.socks4
        if prot == "socks5":
          inc counter.socks5
      else:
        inc fails
    if fails == protocols.len:
      inc counter.fail
    else:
      inc counter.succ      
    inc counter.done
    log counter.done, "/", counter.total


proc run_workers(workers:int, udata: Udata) {.async.}  =
  var ts: seq[Future[void]]
  for i in 0..workers-1:
    ts.add proxay_worker(udata)
  for f in ts:
    await f


proc proxay_thread(p: pointer) {.thread.} =
  var 
    udata = cast[ptr Udata](p)[]
    args = udata[0]
    v_workers = args.get("workers", 100)
  
  waitFor run_workers(v_workers, udata)

scraper "proxay":
  ra "arg1", help = "a file with proxies to check"
  ra "threads", def = 0, help = "number of threads"
  ra "workers", def = 100, help = "number of workers per thread"
  # ra "protocols", def = g_protocols, help = "protocols to check"
  ra "max", def = 1000000, help = "max proxies to check"
  ra "working", def = 1000000, help = "will stop checking when working amount is found"
  ra "fout", def = "working.txt", help = "file to output working proxies to"
  ra "sources", def = false, help = "treats arg1 as a file with sources instead"
  exec:
    gag v_file, "arg1"
    gag v_sources, "sources", false
    gag v_threads, "threads", 0
    gag v_max, "max", 1000000
    gag v_workers, "workers", 100
    gag v_fout, "fout", "working.txt"
    # let v_fout = args.get("fout", "working.txt")

    var
      channel = newShared[Channel[string]]()
      write_channel = newShared[Channel[string]]()
    channel[].open()    
    write_channel[].open()

    var udata = newShared[Udata]()
    udata[][0] = args
    udata[][1] = Counter()
    udata[][2] = channel
    udata[][3] = write_channel
    
    var counter = udata[][1]
     
    {.cast(gcsafe).}:
      var proxies: HashSet[string]
      dbg v_file
      if v_file != "":
        var lines: seq[string]
        for line in v_file.lines:
          lines.add line
        if v_sources:
          proxies = waitFor process_pages_sequential(v_max, lines)
        else:
          proxies = lines.toHashSet
      else:
        proxies = waitFor process_pages_sequential(v_max, g_sources.toSeq)

      log "TOTAL PROXIES FOUND:", proxies.len
      for p in proxies:
        channel[].send p
      counter.total = proxies.len
      
    # for proxy in v_file.read_proxy_file: proxay_send proxy

    var fdata = newShared[EZWriteData]()
    fdata[][0] = v_fout
    fdata[][1] = write_channel
    var tg1 = ezspawn(ez_write_thread, fdata)
    
    if v_threads == 0:
      # 1 * v_workers
      waitFor run_workers(v_workers, udata[])
    else:    
      # v_threads * v_workers
      var tg2 = ezspawn(proxay_thread, udata, v_threads)
      tg2.ezsync()
    
    log "done checking proxies..."
    write_channel[].close()
    channel[].close()

    tg1.ezsync()

    log "success", counter.succ
    log "working", counter.working
    log "total", counter.total
    log "done", counter.done
    # log "requests", counter.done * args.get("protocols", g_protocols).len

    deallocShared(udata)
    deallocShared(fdata)
