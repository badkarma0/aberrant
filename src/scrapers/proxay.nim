


let
  g_sources = [
    "https://premproxy.com/socks-list/ip-port/3.htm",
    "https://proxyscrape.com/proxies/SocksProxies.txt",
    "https://premproxy.com/socks-list/ip-port/9.htm",
    "https://premproxy.com/socks-list/ip-port/8.htm",
    "https://premproxy.com/socks-list/ip-port/1.htm",
    "https://premproxy.com/socks-list/ip-port/6.htm",
    "https://premproxy.com/socks-list/ip-port/5.htm",
    "http://proxy-daily.com/proxy/getproxymanual.php?limit=50000&filter=socks5",
    "http://proxy-daily.com/proxy/getproxymanual.php?limit=50000&filter=socks4",
    "https://premproxy.com/socks-list/ip-port/4.htm",
    "http://proxysearcher.sourceforge.net/Proxy%20List.php?type=socks",
    "https://premproxy.com/socks-list/ip-port/2.htm",
    "https://premproxy.com/socks-list/ip-port/10.htm",
    "https://premproxy.com/socks-list/ip-port/7.htm",
    "https://www.proxydocker.com/en/proxylist/search?port=All&type=All&anonymity=All&country=All&city=All&state=All&need=Google",
    "https://proxydb.net/?offset=150",
    "https://proxydb.net/?offset=105",
    "http://nntime.com/proxy-updated-06.htm",
    "https://www.proxydocker.com/en/proxylist/type/HTTPS",
    "https://freevpn.ninja/free-proxy/txt",
    "http://proxytime.ru/http",
    "http://nntime.com/proxy-updated-07.htm",
    "http://premiumproxy.net",
    "https://premproxy.com/list/",
    "https://www.proxydocker.com/en/proxylist/port/80",
    "https://proxydb.net/?offset=60https://www.proxydocker.com/en/proxylist/port/8081",
    "http://free-proxy-list.net/anonymous-proxy.html",
    "http://nntime.com/proxy-updated-10.htm",
    "http://sslproxies24.blogspot.in/feeds/posts/default",
    "https://proxydb.net/?offset=120",
    "https://www.proxydocker.com/en/proxylist/port/9000",
    "http://vipaccounts24.blogspot.com/",
    "http://rootjazz.com/proxies/proxies.txt",
    "https://www.spoofs.de/feeds/posts/default",
    "http://www.vipsocks24.net/feeds/posts/default",
    "https://www.proxydocker.com/en/proxylist/port/8088",
    "https://proxydb.net/?offset=15",
    "https://www.proxydocker.com/en/proxylist/port/8118",
    "http://proxyape.com/",
    "https://www.proxydocker.com/en/proxylist/search?port=All&type=All&anonymity=All&country=All&city=All&state=All&need=Social",
    "http://nntime.com/proxy-updated-03.htm",
    "https://proxydb.net/?offset=75",
    "https://www.my-proxy.com/free-proxy-list-3.html",
    "https://www.my-proxy.com/free-transparent-proxy.html",
    "http://highbroadcast-proxy.blogspot.com/feeds/posts/default",
    "http://socksproxylist24.blogspot.com/feeds/posts/default",
    "https://www.proxydocker.com/en/proxylist/port/53281",
    "https://proxydb.net/?offset=90",
    "https://www.my-proxy.com/free-proxy-list-6.html",
    "http://premiumproxy.net/anonymous-proxy-list.php",
    "https://guncelproxy.com/",
    "http://proxyandproxytools.blogspot.com/feeds/posts/default",
    "https://55utd55.com/",
    "https://www.proxydocker.com/en/proxylist/port/8123",
    "http://proxylistchecker.org/proxylists.php?t=elite",
    "http://free-fresh-proxy-daily.blogspot.com/feeds/posts/default",
    "https://www.proxydocker.com/en/proxylist/port/3128",
    "http://nntime.com/proxy-updated-05.htm",
    "http://nntime.com/proxy-updated-09.htm",
    "http://nntime.com/proxy-updated-01.htm",
    "https://premproxy.com/socks-list/{01-20}.htm",
    "https://www.proxydocker.com/en/proxylist/port/10000",
    "https://www.proxydocker.com/en/proxylist/port/8085",
    "http://freshssh-list2018.blogspot.com/feeds/posts/default",
    "https://worldproxy.info/",
    "http://nntime.com/proxy-updated-04.htm",
    "https://www.proxydocker.com/en/proxylist/search?port=All&type=All&anonymity=All&country=All&city=All&state=All&need=SEO",
    "http://www.live-socks.net/feeds/posts/default",
    "https://www.proxydocker.com/en/proxylist/port/8080",
    "https://proxy50-50.blogspot.com/",
    "http://nntime.com/proxy-updated-08.htm",
    "https://proxydb.net/?offset=135",
    "http://www.socks24.org/feeds/posts/default",
    "http://www.megaproxylist.net/",
    "http://feeds.feedburner.com/proxypandora",
    "http://newfreshproxies24.blogspot.com/feeds/posts/default",
    "https://www.proxydocker.com/en/proxylist/search?port=All&type=All&anonymity=All&country=All&city=All&state=All&need=BOT",
    "http://getfreeproxylists.blogspot.com/",
    "https://www.my-proxy.com/free-elite-proxy.html",
    "https://www.sslproxies.org/",
    "http://premiumproxy.net/http-proxy-list.php",
    "https://www.my-proxy.com/free-proxy-list-10.html",
    "https://www.proxydocker.com/en/proxylist/port/8888",
    "https://proxydb.net/?offset=30",
    "http://txt.proxyspy.net/proxy.txt",
    "http://spys.ru/free-proxy-list/RU/",
    "https://www.my-proxy.com/free-proxy-list-5.html",
    "http://proxiatyomia.blogspot.com/feeds/posts/default",
    "https://www.proxydocker.com/en/proxylist/port/65000",
    "https://topproxy.info/",
    "https://www.proxydocker.com/en/proxylist/port/1080",
    "https://www.my-proxy.com/free-proxy-list-7.html",
    "https://www.my-proxy.com/free-anonymous-proxy.html",
    "https://www.my-proxy.com/free-proxy-list-4.html",
    "http://blog.proxies24.com/",
    "https://www.proxydocker.com/en/proxylist/port/14",
    "http://fineproxy.org/eng/fresh-proxies/",
    "http://www.proxyserverlist24.top/feeds/posts/default",
    "http://nntime.com/proxy-updated-02.htm",
    "http://premiumproxy.net/https-ssl-proxy-list.php",
    "https://www.socks-proxy.net/",
    "https://www.my-proxy.com/free-proxy-list-2.html",
    "https://proxydb.net/?offset=45",
    "https://www.my-proxy.com/free-proxy-list.html",
    "https://www.my-proxy.com/free-proxy-list-8.html",
    "https://www.my-proxy.com/free-proxy-list-9.html",
    "https://www.proxydocker.com/en/proxylist/type/HTTP",
    "https://proxyfreaks.com/",
    "https://www.proxydocker.com/en/proxylist/port/808"
  ]

import ../libscrape
import sets, re, threadpool, ../libscrape/libcurl, asyncdispatch, httpclient

type 
  Counter = ref object
    fail,succ,done,total,http,https,socks4,socks5: int
  Udata = (ArgStore, Counter, ptr Channel[string], ptr Channel[string])
const 
  azenv = "http://azenv.net"
  g_protocols = ["http", "https", "socks4", "socks5"]

let
  r_ip_port = re"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5}"

iterator read_proxy_file(file: string): string =
  for line in file.lines:
    if line.strip.len != 0:
      yield line

proc process_page(url: string): Future[HashSet[string]] {.async.} =
  var client = newAsyncHttpClient()
  log "get", url
  var data = ""
  try:
    data = await client.getContent(url)
  except Exception:
    discard
  for m in data.findAll(r_ip_port):
    result.incl m
  log "found", result.len, "proxies"

proc process_pages(): Future[HashSet[string]] {.async.} =
  var ts: seq[Future[HashSet[string]]]
  for source in g_sources:
    ts.add process_page(source)  
  for f in ts:
    result.incl await f

proc process_pages_sequential(max: int): Future[HashSet[string]] {.async.} =
  var ts: seq[Future[HashSet[string]]]
  for source in g_sources:
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
    protocols = args.get("protocols", g_protocols)
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
        ok = await withTimeout(std_proxy_check(azenv, prox), 5000)
      except Exception:
        ok = false
      if ok:
        log "OK", prox
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
  ra "arg1", req = true, help = "a file"
  ra "threads", def = 0, help = "number of threads"
  ra "workers", def = 100, help = "number of workers per thread"
  ra "protocols", def = g_protocols, help = "protocols to check"
  ra "max", def = 1000, help = "max proxies to check"
  ra "fout", def = "working.txt", help = "file to output working proxies to"
  exec:
    gag v_file, "arg1"
    gag v_threads, "threads", 0
    gag v_max, "max", 1000
    gag v_workers, "workers", 100
    gag v_fout, "fout", "working.txt"

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
      var proxies = waitFor process_pages_sequential(v_max)
      log "TOTAL PROXIES FOUND:", proxies.len
      for p in proxies:
        channel[].send p
      # if v_max == 0:
      #   for p in proxies:
      #     channel.send p
      # else:
      #   for _ in 0..v_max:
      #     channel.send proxies.pop
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

    ezsync(tg1)

    # if not b:
    #   var f = open("working_proxies.txt", fmWrite)
    #   ezloop_noclose write_channel, true:
    #     f.writeLine(message)
    #   f.close()

    log "success", counter.succ
    log "total success", counter.http + counter.https + counter.socks4 + counter.socks5
    log "total", counter.total
    log "done", counter.done
    log "requests", counter.done * args.get("protocols", g_protocols).len

    deallocShared(udata)
    deallocShared(fdata)
