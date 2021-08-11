# libcurl wrapper for downloading and http requests
import ark, lag, url
import libcurl
import os, times, strformat, termstyle, math, strutils
import httpclient
import asyncdispatch
import threadpool
type
  Header* = object
    key*, value*: string
  Options* = ref object
    overwrite*, show_progress*, chunked*: bool
  Flags* = ref object
    skipped: bool
    time: float
  Download* = ref object
    url*, path*: string
    opts*: Options
    flags*: Flags
    headers*: seq[Header]
  Session* = ref object
    headers*: seq[Header]
    cookies*: seq[Header]
  Request* = ref object
    url*: Url
    headers*: seq[Header]
    verb*: string
    body*: string
  Response* = ref object
    url*: Url
    headers*: seq[Header]
    code*: int
    body*: string
    error*: string
  CurlRequest = ref object
    curl: Pcurl
    headerData: ref string
    bodyData: ref string
    headerList: Pslist
  CurlRange = ref object
    file: File
    cur: int
    total: int
    str: string

arg v_dry, "dry", false, help = "no downloading"
arg v_np, "np", false, help = "dont log path when downloading"
arg v_chunked, "chunked", false, help = "chunked download (might be faster)"
arg v_show_progress, "progress", false, help = "show progress"
arg v_curl_verbose, "curl-verbose", false, help = "curl verbose"
ra "chunk-size", "", help = "if chunked, chunk size"
arg v_chunk_count, "chunk-count", 0, help = "if chunked, chunk count, overwrites chunk-size"
arg v_sequential, "seq", false, help = "no threaded downloading"
arg v_overwrite, "overwrite", false, help = "overwrite existing files"
var
  download_channel: Channel[Download]
  dls: seq[Download]
  p_dls = dls.addr
  httpCclient = newHttpClient()

download_channel.open()
const CRLF = "\r\n"

func `[]`*(headers: seq[Header], key: string): string =
  ## Get a key out of headers. Not case sensitive.
  ## Use a for loop to get multiple keys.
  for header in headers:
    if header.key.toLowerAscii() == key.toLowerAscii():
      return header.value

func `[]=`*(headers: var seq[Header], key, value: string) =
  ## Sets a key in the headers. Not case sensitive.
  ## If key is not there appends a new key-value pair at the end.
  for header in headers.mitems:
    if header.key.toLowerAscii() == key.toLowerAscii():
      header.value = value
      return
  headers.add(Header(key: key, value: value))

proc set_header*(s: Session, key, value: string) =
  s.headers[key] = value

proc set_cookie*(s: Session, key, value: string) =
  s.cookies[key] = value
  s.headers["cookie"] = s.cookies.join("; ") 

proc `$`*(req: Request): string =
  ## Turns a req into the HTTP wire format.
  var path = req.url.path
  if path == "":
    path = "/"
  if req.url.query.len > 0:
    path.add "?"
    path.add req.url.search

  result.add "GET " & path & " HTTP/1.1" & CRLF
  result.add "Host: " & req.url.hostname & CRLF
  for header in req.headers:
    result.add header.key & ": " & header.value & CRLF
  result.add CRLF

proc `$`*(dl: Download): string =
  let a = red "=>"
  if v_np:
    return &"{dl.url}"
  let b = green dl.path
  result = &"{dl.url}\n{a} {b}"

proc `$$`(dl: Download): string =
 result = &"""{dl}
    \n\toverwrite = {dl.opts.overwrite}
  """

const byteUnits = ['B', 'K', 'M', 'G', 'T', 'P', 'E']
func bytesToHR(byts: BiggestInt): string =
 var bytes = byts
 var i = 0
 while bytes > 1024:
  bytes = bytes div 1024
  i += 1
 $bytes & byteUnits[i]

func HRtoBytes(s: string): int =
  var hr = s.strip
  let c = hr[hr.len-1]
  if c.isDigit:
    return hr.parseInt
  let i = byteUnits.find(c)
  let n = hr[0.. hr.len-2].parseInt
  if i == -1: return n
  debugEcho n,i
  pow(1024.toFloat, i.toFloat).toInt * n
    

# ----------------------------------------------------------------
# curl stuff
# ----------------------------------------------------------------

type
  HttpException = ref object of CatchableError
  CurlFileWriteFailed = ref object of HttpException

proc curl_write_file(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer
): int =  
  let outbuf = cast[ptr File](outstream)
  let wsize = outbuf[].writeBuffer(buffer, count)
  if wsize != count:
    raise CurlFileWriteFailed()
  size * count

proc curl_write_file_chunked(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer
): int =  
  let crange = cast[ptr CurlRange](outstream)[]
  crange.file.setFilePos crange.cur
  let wsize = crange.file.writeBuffer(buffer, count)
  crange.file.flushFile()
  if wsize != count:
    raise CurlFileWriteFailed()
  crange.cur += wsize 
  size * count

proc curl_write_gen(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer
): int =
  if size != 1:
    raise CurlFileWriteFailed()
  let 
    outbuf = cast[ref string](outstream)
    i = outbuf[].len
  outbuf[].setLen(outbuf[].len + count)
  copyMem(outbuf[][i].addr, buffer, count)
  result = size * count

proc xfer(data: pointer, dltot, dlnow, ultot, ulnow: float) =
  echo &"{dlnow}/{dltot}"

# CurlRequest methods

template opt(cr: CurlRequest, o: Option, x: typed) =
  discard cr.curl.easy_setopt(o,x)

template opts(cr: CurlRequest, body: untyped) =
  proc `=>`[T](option: Option, arg: T) {.varargs.} =
    discard cr.curl.easy_setopt(option, arg)
  block:body

proc curl_easy_request: CurlRequest  =
  let cr = CurlRequest()
  cr.curl = easy_init()
  cr.headerData = new string
  cr.bodyData = new string
  opt cr, OPT_WRITEDATA, cr.bodyData
  opt cr, OPT_WRITEHEADER, cr.headerData
  opt cr, OPT_WRITEFUNCTION, curl_write_gen
  opt cr, OPT_HEADERFUNCTION, curl_write_gen
  opt cr, OPT_USERAGENT, "Aberrant (curl)"
  opt cr, OPT_ACCEPT_ENCODING, ""
  if v_curl_verbose:
    opt cr, OPT_VERBOSE, 1
  when defined(windows):
    opt cr, OPT_CAINFO, "cacert.pem"
  cr

proc set_header(cr: CurlRequest, k,v:string)  =
  cr.headerList = cr.headerList.slist_append(k & ": " & v)
  opt cr, OPT_HTTPHEADER, cr.headerList

proc set_headers(cr: CurlRequest, hs: seq[Header]) =
  for h in hs:
    cr.headerList = cr.headerList.slist_append(h.key & ": " & h.value)
  opt cr, OPT_HTTPHEADER, cr.headerList

proc get_headers(cr: CurlRequest): seq[Header] =
  for line in cr.headerData[].split(CRLF):
    let arr = line.split(":", 1)
    if arr.len == 2:
      result[arr[0].strip()] = arr[1].strip()
proc get_body(cr: CurlRequest): string =
  cr.bodyData[]

proc cleanup(cr: CurlRequest) =
  cr.curl.easy_cleanup()
  cr.headerList.slist_free_all()

proc run(cr: CurlRequest): Code =
  cr.curl.easy_perform()

# END CurlRequest methods

proc fetch*(req: Request): Response {.gcsafe.} =
  result = Response()

  let cr = curl_easy_request()
  opts cr:
    OPT_URL => $req.url
    OPT_FOLLOWLOCATION => 1
    OPT_CUSTOMREQUEST => req.verb.toUpperAscii()
    if req.body.len > 0:
      OPT_POSTFIELDS => req.body
  cr.set_headers req.headers
  let ret = cr.run()

  result.url = req.url
  if ret == E_OK:
    var code: uint32
    discard cr.curl.easy_getinfo(INFO_RESPONSE_CODE, code.addr)
    result.headers = cr.get_headers()
    result.body = cr.get_body()
    result.code = code.int
  else:
    result.error = $easy_strerror(ret)
  cr.cleanup()

# do a HEAD request
proc head*(req: Request): seq[Header] =
  # req.headers["Connection"] = "close"
  let cr = curl_easy_request()
  opts cr:
    OPT_URL => $req.url
    OPT_NOBODY => 1
    OPT_FOLLOWLOCATION => 1
  cr.set_headers req.headers
  discard cr.run()
  cr.cleanup()
  cr.get_headers()

proc fetch*(url: string, verb = "get", headers = newSeq[Header]()): string =
  let req = Request()
  req.url = parseUrl(url)
  req.verb = verb
  req.headers = headers
  let res = req.fetch()
  if res.code == 200:
    return res.body

proc isOk*(res: Response): bool =
  return res.error.len == 0 and 200 < res.code and res.code > 299

proc curl_download_chunked*(dl: Download) =
  let req = Request()
  req.url = dl.url.parseUrl
  req.headers = dl.headers
  let headers = req.head 
  dbg headers
  let fr = headers["Content-Length"].parseInt
  let cm = multi_init()

  var 
    chunk_size:int = "10M".HRtoBytes
    v_chunk_size = ga"chunk-size"
  if v_chunk_count != 0:
    chunk_size = toInt fr / v_chunk_count
  elif v_chunk_size != "":
    chunk_size = v_chunk_size.HRtoBytes

  # generate ranges
  var 
    c = fr
    i = 0
    ranges: seq[CurlRange]
  while c > 0:
    var crange = CurlRange()
    ranges.add crange
    if chunk_size > c:
      crange.cur = fr - c
      crange.str = $(i * chunk_size) & "-"
    else:
      crange.cur = i * chunk_size
      crange.str = $(i * chunk_size) & "-" & $((i + 1) * chunk_size)

    var f = open(dl.path, fmWrite)
    crange.file = f

    i+=1
    c -= chunk_size

  # create an easy for each range
  var crs: seq[CurlRequest]
  for crange in ranges:
    var cr = curl_easy_request()
    crs.add cr
    opts cr:
      OPT_URL => dl.url
      OPT_HTTPGET => 1
      OPT_FOLLOWLOCATION => 1
      OPT_WRITEDATA => crange.unsafeAddr
      OPT_WRITEFUNCTION => curl_write_file_chunked
    cr.set_headers(dl.headers)
    cr.set_header("range", "bytes="&crange.str)
    discard cm.multi_add_handle cr.curl

  # wait 
  var 
    hc:int32 = 1
    mc: int32
    code: Mcode
  discard cm.multi_perform(hc)
  
  while hc != 0:
    # dbg "polling", hc
    sleep 100
    # code = cm.multi_poll(Waitfd(), 0, 1000, hc)
    # dbg code
    code = cm.multi_perform(hc)
    # dbg code

  # cleanup
  for cr in crs:
    cr.cleanup
  for r in ranges:
    dbg r.total, r.cur
    r.file.close()

  return

proc curl_download*(dl: Download) =  
  var file = open(dl.path, fmWrite)

  if file == nil:
    raise newException(IOError, &"Failed to open file {dl.url}")

  if dl.opts.chunked or v_chunked:
    file.close()
    try:
      dl.curl_download_chunked
    except:
      dbg_exception()
    return
  
  let no_progress = if dl.opts.show_progress or v_show_progress: 0 else: 1

  let cr = curl_easy_request()
  opts cr:
    OPT_HTTPGET => 1
    OPT_WRITEDATA => addr file
    OPT_WRITEFUNCTION => curl_write_file
    OPT_FOLLOWLOCATION => 1
    OPT_URL => dl.url
    # OPT_VERBOSE => 1
    # OPT_PROGRESSFUNCTION => xfer
    OPT_NOPROGRESS => no_progress
  cr.set_headers(dl.headers)
  let ret = cr.run()
  file.close()
  cr.cleanup()

  if ret != E_OK:
    raise newException(Exception, "download failed")

# ------------------------------------------------------
# public download/request api
# ------------------------------------------------------

proc download_base(dl: Download) =
  var path = dl.url.parseUrl.path
  if dl.path.len > 0:
    path = dl.path

  path.parentDir.createDir

  if path.fileExists and not dl.opts.overwrite:
    dl.flags.skipped = true
    return

  let st = cpuTime()
  dl.curl_download()
  dl.flags.time = round(cpuTime() - st, 3)

proc make_download*(url, path: string, opts: Options, flags: Flags): Download =
  result = Download(
    url: url,
    path: path,
    opts: opts,
    flags: flags
  )

proc make_download*(url, path = "", overwrite = v_overwrite, show_progress = v_show_progress): Download =
  result = make_download(
    url, path, Options(
      overwrite: overwrite,
      show_progress: show_progress
    ), Flags(
      time: 0,
      skipped: false
    )
  )

  
const
  s_skipped = italic("Skipped")
  s_downloaded = bold("Downloaded")
  s_failed = "Failed".style(termRed & termNegative)
  s_attempt = "Try Download"

proc download*(dl: Download) =
 try:
  if v_dry:
    log &"Dry Find {dl}"
    return
  logv &"{s_attempt}: {dl.url}"
  dl.download_base()
  let fs = dl.path.getFileSize.bytesToHR
  let t = dl.flags.time
  if dl.flags.skipped:
   log &"{s_skipped}[{fs}]: {dl}"
  else:
   log &"{s_downloaded}[{t}s][{fs}]: {dl}"
 except Exception:
  err &"{s_failed}: {dl}"

proc download*(url, path: string, overwrite = false, show_progress = false) =
 download make_download(url, path, overwrite, show_progress)

proc download_worker {.thread.} =
  lag_add_thread()
  while true:
    var tried = download_channel.tryRecv()
    if not tried.dataAvailable: 
      lag_del_thread()
      break
    let dl = tried.msg
    dl.download()

proc download*(urls: openArray[string], path: string, headers: seq[Header] = @[]) =
  if urls.len <= 0:
    return
  
  path.createDir

  if not v_sequential:

    for url in urls:
      let p = url.parseUrl
      let dl = make_download(url, path / p.path.extractFilename)
      dl.headers = headers
      download_channel.send dl

    for i in 0..10:
      spawn download_worker()
    sync()
  else:
    for url in urls:
      let p = url.parseUrl
      let dl = make_download(url, path / p.path.extractFilename)
      dl.headers = headers
      dl.download


when isMainModule:
  const
    url = "http://ipv4.download.thinkbroadband.com/1GB.zip"
  download(url, url.extractFilename)