import ark, lag
import libcurl
import os, times, strformat, termstyle, urlly, math, strutils

type
  Header* = object
    key*: string
    value*: string
  Options* = ref object
    overwrite: bool
  Flags* = ref object
    skipped: bool
    time: float
  Download* = ref object
    url*, path*: string
    opts*: Options
    flags*: Flags
    headers*: seq[Header]

arg v_dry, "dry", false, help = "no downloading"
arg v_np, "np", false, help = "dont log path when downloading"

var
  downloadChannel: Channel[Download]
downloadChannel.open()

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

proc curl_write_file(
  buffer: cstring,
  size: int,
  count: int,
  outstream: pointer
): int =  
  let outbuf = cast[ptr File](outstream)
  let wsize = outbuf[].writeBuffer(buffer, count)
  if wsize != count:
    raise newException(Exception, &"fucking died lmao, {wsize}, {count}")
  result = size * count

template curl(body: untyped) =
  let curl {.inject.} = easy_init()
  template `>`(option: Option, arg: untyped) =
    discard curl.easy_setopt(option, arg)
  block:
    body
  curl.easy_cleanup()

proc xfer(data: pointer, dltot, dlnow, ultot, ulnow: float) =
  echo &"{dlnow}/{dltot}"

proc download(url, path: string, headers: seq[Header]) =  
  var file = open(path, fmWrite)

  if file == nil:
    raise newException(IOError, "file is nil")

  var headerList: Pslist
  for header in headers:
    headerList = slist_append(headerList, header.key & ": " & header.value)

  curl:

    OPT_HTTPHEADER > headerList
    OPT_USERAGENT > "Mozilla 5.0"
    OPT_HTTPGET > 1
    OPT_WRITEDATA > addr file
    OPT_WRITEFUNCTION > curl_write_file
    OPT_FOLLOWLOCATION > 1

    OPT_URL > url
    # OPT_VERBOSE > 1
    # OPT_PROGRESSFUNCTION > xfer
    # OPT_NOPROGRESS > 0

    let ret = curl.easy_perform()

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
 result = &"{dl.url} {a} {b}"

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
  download(dl.url, dl.path, dl.headers)
  dl.flags.time = round(cpuTime() - st, 3)

proc makeDownload*(url, path: string, opts: Options, flags: Flags): Download =
  result = Download(
    url: url,
    path: path,
    opts: opts,
    flags: flags
  )

proc makeDownload*(url, path = "", overwrite = false): Download =
  result = makeDownload(
    url, path, Options(
      overwrite: overwrite
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

proc download*(url, path: string, overwrite = false) =
 download makeDownload(url, path, overwrite)



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