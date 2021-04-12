import puppy
import os
# import cpuinfo
import json
import urlly
import strformat, strutils
import termstyle, parseopt
import times
import math
import base





# LOGGING
var
 logChannel: Channel[string]
 lt*: Thread[void]
 lt_do_blocking* = true
 lt_do_debug* = false
 lt_do_verbose* = false
 lt_show_thread* = true
 lt_exit = false

proc logger() =
 while true:
  let tried = logChannel.tryRecv()
  if not tried.dataAvailable:
    if lt_exit:
      break
    continue
  echo tried.msg

logChannel.open()
createThread(lt, logger)

proc exit_logger* =
 lt_exit = true
 joinThread(lt)

template ln(n: string) =
  var nn = ""
  if lt_show_thread:
    let tid {.inject.} = getThreadId()
    nn = &"[{tid}]" & n
  if lt_do_blocking:
    logChannel.send(nn)
  else:
    discard logChannel.trySend(nn)

proc log*(msg: string) =
  ln "[LOG] " & msg

proc err*(msg: string) =
  ln red("[ERR] ") & msg

proc logv*(msg: string) =
  if lt_do_verbose:
    ln "[LOG] " & msg

proc dbg*(msg: string) =
  if lt_do_debug:
    ln yellow("[DBG] ") & msg

# DOWNLOADS
type
 Options* = ref object
  overwrite: bool
 Flags* = ref object
  skipped: bool
  time: float
 Download* = ref object
  url, path: string
  opts: Options
  flags: Flags

var
 downloadChannel: Channel[Download]
downloadChannel.open()

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

const
 s_skipped = italic("Skipped")
 s_downloaded = bold("Downloaded")

proc download_base(dl: Download) =
 var path = dl.url.parseUrl.path
 if dl.path.len > 0:
  path = dl.path

 if path.fileExists and not dl.opts.overwrite:
  dl.flags.skipped = true
  return

 let req = Request(
   url: parseUrl(dl.url),
   verb: "get"
 )
 let st = cpuTime()
 let res = fetch(req)
 if res.code == 200:
  writeFile(path, res.body)
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
  dl.download_base()
  let fs = dl.path.getFileSize.bytesToHR
  let t = dl.flags.time
  if dl.flags.skipped:
   log &"{s_skipped}[{fs}]: {dl}"
  else:
   log &"{s_downloaded}[{t}s][{fs}]: {dl}"
 except Exception:
  err "Download failed"

proc download*(url, path: string, overwrite = false) =
 download makeDownload(url, path, overwrite)



proc downloadFromChannel {.thread.} =
 while true:
  let data = downloadChannel.tryRecv()
  if not data.dataAvailable: break
  let dl = data.msg
  dl.download()

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


# ARGS

proc parse(): seq[KVPair] =
  var args: seq[KVPair] = @[]
  var ac = 0
  for kind, key, val in getopt():
    case kind:
    of cmdArgument:
      args.add (key: &"arg{ac}", value: key)
      ac += 1
    of cmdLongOption, cmdShortOption:
      if val == "":
        args.add (key: key, value: "true")
      else:
        args.add (key: key, value: val)
    of cmdEnd:
      break
  args

template loa(name: string, def: typed, body: untyped) =
  for ar {.inject.} in parse():
    if ar.key == name:
      try:
        block:
          body
      except Exception:
        err &"{name} has wrong type"
  return def

proc ga*(name: string, def = ""): string =
  loa name, def:
    return ar.value
proc ga*(name: string, def: bool): bool =
  loa name, def:
    return ar.value.parseBool
proc ga*(name: string, def: int): int =
  loa name, def:
    return ar.value.parseInt
proc ga*(name: string, def: float): float =
  loa name, def:
    return ar.value.parseFloat

# MISC

proc `/=`*(p1: var string, p2: string) =
  # append something to a path, short for "p1 = p1 / p2"
  p1 = p1 / p2