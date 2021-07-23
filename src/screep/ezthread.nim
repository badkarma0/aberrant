import tables, os
var
  exit = false
  threads: seq[Thread[void]]
  channels = initTable[string, pointer]()

template ezthread*(cname: string, T: typed, body: untyped) =
  
  var
    thread: Thread[void]
    channel: Channel[T]

  channel.open()
  channels[cname] = channel.addr

  
  proc ez_worker {.thread.} =
    while true:
      sleep 200
      echo cast[int](channel.addr)
      echo cast[int](channels[cname])
      let tried = channel.tryRecv()
      if not tried.dataAvailable:
        if exit:
          channel.close()
          break          
        continue
      let message {.inject.}: T = tried.msg
      block:
        body
  
  thread.createThread ez_worker
  threads.add thread


proc ez_get_channel*(name: string): pointer =
  channels[name]

proc ezexit* =
  exit = true
  for t in threads:
    t.joinThread()
  