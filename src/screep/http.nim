import ark, lag
import libcurl, zippy
import os, times, strformat, termstyle, urlly, math, strutils
import macros
type
  Header* = object
    key*, value*: string
  Options* = ref object
    overwrite: bool
    show_progress: bool
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

arg v_dry, "dry", false, help = "no downloading"
arg v_np, "np", false, help = "dont log path when downloading"

var
  downloadChannel: Channel[Download]
downloadChannel.open()

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


proc curl_write_file(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer
): int =  
  let outbuf = cast[ptr File](outstream)
  let wsize = outbuf[].writeBuffer(buffer, count)
  if wsize != count:
    raise newException(Exception, &"fucking died lmao, file write {wsize}, {count}")
  result = size * count

proc curl_write_gen(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer
): int =
  if size != 1:
    raise newException(Exception, &"fucking died lmao, gen write {count}")
  let 
    outbuf = cast[ref string](outstream)
    i = outbuf[].len
  outbuf[].setLen(outbuf[].len + count)
  copyMem(outbuf[][i].addr, buffer, count)
  result = size * count

template T_curl(body: untyped) =
  let curl {.inject.} = easy_init()
  var 
    headerData: ref string = new string
    bodyData: ref string = new string
    headerList: Pslist
  template T_setup(sbody: untyped) =
    template `>`(option: Option, arg: untyped) =
      discard curl.easy_setopt(option, arg)
    template T_set_header(key, val: string) =
      headerList = headerList.slist_append(key & ": " & val)
    template T_set_headers(hs: seq[Header]) =
      for h in hs:
        headerList = headerList.slist_append(h.key & ": " & h.val)
    OPT_WRITEDATA > bodyData
    OPT_WRITEHEADER > headerData
    OPT_WRITEFUNCTION > curl_write_gen
    OPT_HEADERFUNCTION > curl_write_gen
    block:
      sbody
    OPT_HTTPHEADER > headerList
  template T_run(rbody: untyped) =
    let ret {.inject.} = curl.easy_perform()
    var headers {.inject.}: seq[Header]
    for line in headerData[].split(CRLF):
        let arr = line.split(":", 1)
        if arr.len == 2:
          headers[arr[0].strip()] = arr[1].strip()
    var body {.inject.} = bodyData[]
    template `>`(option: INFO, arg: untyped) =
      discard curl.easy_getinfo(option, arg)
    block:
      rbody
  block:
    body
  curl.easy_cleanup()
  headerList.slist_free_all()


proc xfer(data: pointer, dltot, dlnow, ultot, ulnow: float) =
  echo &"{dlnow}/{dltot}"

proc add_default_headers(req: Request) =
  if req.headers["user-agent"].len == 0:
    req.headers["user-agent"] = "Aberrant"
  if req.headers["accept-encoding"].len == 0:
    # If there isn't a specific accept-encoding specified, enable gzip
    req.headers["accept-encoding"] = "gzip"

proc fetch*(req: Request): Response =
  T_curl:
    T_setup:
      req.add_default_headers()
      T_set_headers req.headers
      OPT_URL > $req.url
      OPT_FOLLOWLOCATION > 1
      OPT_CUSTOMREQUEST > req.verb.toUpperAscii()
      if req.body.len > 0:
        OPT_POSTFIELDS > req.body
    T_run:
      result.url = req.url
      if ret == E_OK:
        var code: uint32
        INFO_RESPONSE_CODE > code.addr
        result.headers = headers
        result.body = body
        result.code = code.int
        if result.headers["Content-Encoding"] == "gzip":
          result.body = uncompress(result.body, dfGzip)
      else:
        result.error = $easy_strerror(ret)

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

proc download(url, path: string, headers: seq[Header], no_progress = 1) =  
  var file = open(path, fmWrite)

  if file == nil:
    raise newException(IOError, "file is nil")

  curl:
    setup:
      set_headers headers

      OPT_USERAGENT > "Aberrant"
      OPT_HTTPGET > 1
      OPT_WRITEDATA > addr file
      OPT_WRITEFUNCTION > curl_write_file
      OPT_FOLLOWLOCATION > 1

      OPT_URL > url
      # OPT_VERBOSE > 1
      # OPT_PROGRESSFUNCTION > xfer
      OPT_NOPROGRESS > no_progress
    run:
      file.close()

      if ret == E_OK:
        return
        # strm.close()
        # echo(webData[])
      else:
        raise newException(Exception, "download failed")

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
proc bytesToHR(byts: BiggestInt): string =
 var bytes = byts
 var i = 0
 while bytes > 1024:
  bytes = bytes div 1024
  i += 1
 $bytes & byteUnits[i]

const
  s_skipped = italic("Skipped")
  s_downloaded = bold("Downloaded")
  s_failed = "Failed".style(termRed & termNegative)

proc download_base(dl: Download) =
  var path = dl.url.parseUrl.path
  if dl.path.len > 0:
    path = dl.path

  path.parentDir.createDir

  if path.fileExists and not dl.opts.overwrite:
    dl.flags.skipped = true
    return

  let st = cpuTime()
  let no_progress = if dl.opts.show_progress: 0 else: 1
  download(dl.url, dl.path, dl.headers, no_progress = no_progress)
  dl.flags.time = round(cpuTime() - st, 3)

proc makeDownload*(url, path: string, opts: Options, flags: Flags): Download =
  result = Download(
    url: url,
    path: path,
    opts: opts,
    flags: flags
  )

proc makeDownload*(url, path = "", overwrite = false, show_progress = false): Download =
  result = makeDownload(
    url, path, Options(
      overwrite: overwrite,
      show_progress: show_progress
    ), Flags(
      time: 0,
      skipped: false
    )
  )

# proc makeDownload*(url, path = ""): Download =
 # return makeDownload(url, path, default(Options))

proc download*(dl: Download) =
 try:
  if v_dry:
    log &"Dry Find {dl}"
    return
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
 download makeDownload(url, path, overwrite, show_progress)



proc downloadFromChannel {.thread.} =
  lag_add_thread()
  while true:
    let tried = downloadChannel.tryRecv()
    if not tried.dataAvailable: 
      lag_del_thread()
      break
    let dl = tried.msg
    dl.download()

proc download*(urls: openArray[string], path: string, headers: seq[Header]) =
  if urls.len <= 0:
    return

  var threads: array[10, Thread[void]]

  path.createDir

  for url in urls:
    let dl = makeDownload(url, path / url.extractFilename)
    dl.headers = headers
    downloadChannel.send(dl)

  for i in 0..threads.high:
    createThread(threads[i], downloadFromChannel)
  joinThreads(threads)

proc download*(urls: openArray[string], path: string) =
  download(urls, path, @[])

when isMainModule:
  const
    url = "http://ipv4.download.thinkbroadband.com/1GB.zip"
  download(url, url.extractFilename)