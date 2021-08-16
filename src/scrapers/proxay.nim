


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
import sets, re, threadpool, ../libscrape/libcurl, asyncdispatch

type Counter = ref object
  fail,succ,done,total,http,https,socks4,socks5: int
type Pa = ref object
  p_counter: ptr Counter
  args: ArgStore
const 
  azenv = "http://azenv.net"
  g_protocols = ["http", "https", "socks4", "socks5"]

var
  exit = false
  channel: Channel[string]
  r_ip_port = re"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5}"

iterator read_proxy_file(file: string): string =
  for line in file.lines:
    if line.strip.len != 0:
      yield line

proc proxay_worker(p: pointer) {.thread, async.} =
  let au = azenv.parseUrl
  var 
    ap = cast[ptr (ArgStore, Counter)](p)[]
    args = ap[0]
    counter = ap[1]
    protocols = args.get("protocols", g_protocols)
    f = true
  ezloop_noclose channel, f:
    var fails = 0
    for prot in protocols:
      var r = Request()
      r.url = au
      r.verb = "GET"
      r.proxy = prot & "://" & message
      r.cb_before_run = 
        proc(cr: CurlRequest) =
          opt cr, OPT_TIMEOUT, 5
      log r.proxy
      let res = r.fetch()
      if res.isOk:
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

proc run_workers(v_threads:int, udata: pointer) {.async.}  =
  var ts: seq[Future[void]]
  for i in 0..v_threads-1:
    ts.add proxay_worker(udata)
  for f in ts:
    await f

scraper "proxay":
  ra "arg1", req = true, help = "a file"
  ra "threads", def = 10, help = "number of threads"
  ra "protocols", def = g_protocols, help = "protocols to check"
  exec:
    gag v_file, "arg1"
    gag v_threads, "threads", 10
    # if not v_file.fileExists:
    #   err "file not found"
    #   return
     
    
    var proxies: HashSet[string]
    {.cast(gcsafe).}:
      for source in g_sources:
        let data = fetch(source)
        log "get", source
        var i = 0
        for m in data.findAll(r_ip_port):
          inc i
          proxies.incl m
        log "found", i, "proxies"
        if proxies.len > 100:
          break
    log "TOTAL PROXIES FOUND:", proxies.len

    channel.open()

    for p in proxies:
      channel.send p
    # for proxy in v_file.read_proxy_file: proxay_send proxy

    var udata = newShared[(ArgStore, Counter)]()
    udata[][0] = args
    udata[][1] = Counter()
    var counter = udata[][1]
    counter.total = proxies.len

    # ezspawn(v_threads, proxay_worker, udata)
    # ezsync()

    waitFor run_workers(v_threads, udata)

    log counter.succ
    log counter.total

    # ts.joinThreads()




