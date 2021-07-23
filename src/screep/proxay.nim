import strutils

var
  exit = false
  thread: Thread[void]
  channel: Channel[string]


proc read_proxy_file(file: string): seq[string] =
  for line in file.lines:
    if line.strip.len != 0:
      result.add line

proc proxay_worker {.thread.} =
  var proxies = "proxies.txt".read_proxy_file()
  while true:
    let tried = channel.tryRecv()
    if not tried.dataAvailable:
      if exit:
        channel.close()
        break          
      continue
    let message {.inject.}: string = tried.msg
    
proc proxay_send*(msg: string) =
  channel.send(msg)

proc proxay_init* =
  channel.open()
  thread.createThread proxay_worker

proc proxay_exit* =
  exit = true
  thread.joinThread()

