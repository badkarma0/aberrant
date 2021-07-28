

import ../screep/scraper

var
  r_ip_port = re"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5}"
  exit = false
  channel: Channel[string]

proc read_proxy_file(file: string): seq[string] =
  for line in file.lines:
    if line.strip.len != 0:
      result.add line

proc proxay_worker {.thread.} =
  while true:
    let tried = channel.tryRecv()
    if not tried.dataAvailable:
      if exit:
        break          
      continue
    let message {.inject.}: string = tried.msg
    
proc proxay_send*(msg: string) =
  channel.send(msg)


scraper "proxay":
  ra "arg1", req = true, help = "a file"
  ra "threads", def = 10, help = "number of threads"
  exec:
    var 
      v_file = ga"arg1"
      v_threads = "threads".ga 10
    if not v_file.fileExists:
      err "file not found"
      return
    let proxies = v_file.read_proxy_file
    channel.open()
    var ts: seq[Thread[void]]
    for _ in 0..v_threads:
      var t: Thread[void]
      t.createThread proxay_worker
      ts.add t

    exit = true
    ts.joinThreads()




