import puppy
import os
import htmlparser
import xmltree
import nimquery
# import cpuinfo
import json
import urlly
import uri
import strformat
import termstyle
import times
import math

type
  Options* = ref object
    overwrite: bool
  Download* = ref object
    url, path: string
    opts: Options

var
  downloadChannel: Channel[Download]
downloadChannel.open()

var 
  logChannel: Channel[string]
  lt*: Thread[void]
  verbose* = false
  blocking* = true
  exit* = false 

proc logger() =
  while true:
    let tried = logChannel.tryRecv()
    if exit and not tried.dataAvailable:
      break
    if tried.dataAvailable:
      echo tried.msg

logChannel.open()
createThread(lt, logger)

proc exit_logger* =
  exit = true
  joinThread(lt)

template ln(n: string) =
  if blocking:
    logChannel.send(n)
  else:
    discard logChannel.trySend(n)

proc log*(msg: string) =
  ln "[LOG] " & msg

proc dbg*(msg: string) =
  if verbose:
    ln yellow("[DBG] ") & msg

proc err*(msg: string) =
  ln red("[ERR] ") & msg


proc download*(dl: Download) =
  var path = dl.url.parseUrl.path
  if dl.path.len > 0:
    path = dl.path

  if path.fileExists and not dl.opts.overwrite: 
    return

  let req = Request(
    url: parseUrl(dl.url),
    verb: "get"
  )

  let res = fetch(req)
  if res.code == 200:
    writeFile(path, res.body)

proc makeDownload*(url, path: string, opts: Options): Download =
  result = Download(
    url: url, 
    path: path, 
    opts: opts
  )

proc makeDownload*(url, path = "", overwrite = false): Download =
  result = makeDownload(
    url, path, Options(
      overwrite: overwrite
    )
  )

# proc makeDownload*(url, path = ""): Download =
  # return makeDownload(url, path, default(Options))

proc download*(url, path: string, overwrite = false) =
  download makeDownload(url, path, overwrite)

proc `$`*(dl: Download): string =
  let a = red "=>"
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

proc downloadFromChannel {.thread.} =
  while true:
    let data = downloadChannel.tryRecv()
    if not data.dataAvailable: break
    let dl = data.msg
    try:
      let st = cpuTime()
      dl.download()
      let ft = round(cpuTime() - st, 3)
      let fs = dl.path.getFileSize.bytesToHR
      log &"Downloaded[{ft}s][{fs}]: {dl}"
    except Exception:
      err "Download failed"

proc download*(urls: openArray[string], path: string) =
  if urls.len <= 0:
    return
  
  var threads: array[10, Thread[void]]
  
  path.createDir
  
  for url in urls:
    let dl = makeDownload(url, path / url.extractFilename)
    downloadChannel.send(dl)
  
  for i in 0..threads.high:
    createThread(threads[i], downloadFromChannel)
  joinThreads(threads)

proc `$`*(node: XmlNode, q: string): XmlNode =
  result = node.querySelector(q)

proc `$$`*(node: XmlNode, q: string): seq[XmlNode] =
  result = node.querySelectorAll(q)

proc fetchHtml*(url: urlly.Url): XmlNode =
  let res = fetch($url)
  parseHtml(res)

proc fetchJson*(url: urlly.Url): JsonNode =
  let res = fetch($url)
  parseJson(res)

proc `/`*(url: urlly.Url, ext: string): urlly.Url =
  parseUrl($(parseUri($url) / ext))