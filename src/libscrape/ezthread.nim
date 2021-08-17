
import tables, os
import asyncdispatch, util, lag

type
  ThreadWorker = proc(eztp: pointer) {.thread.}
  EZThread* = ref object
    thread*: Thread[pointer]
    data*: pointer
    channel*: pointer
    exit*: bool
    worker*: ThreadWorker
  EZTS = Table[string, EZThread]

var ezt_registry: EZTS

template ezloop_noclose*[T](channel: Channel[T], eval: untyped, lb: untyped) =
  while true:
    let tried = channel.tryRecv()
    if not tried.dataAvailable:
      if eval:
        break
      sleep 100
      continue
    let message {.inject.}: T = tried.msg
    block:
      lb

template ezloop*[T](channel: Channel[T], eval: untyped, lb: untyped) =
  while true:
    let tried = channel.tryRecv()
    if not tried.dataAvailable:
      if eval:
        channel.close()
        break
      sleep 100
      continue
    let message {.inject.}: T = tried.msg
    block:
      lb

template ezloop*[T](cin,cout: Channel[T], eval: untyped, is_async: untyped = false, lb: untyped,) =
  while true:
    let t_cin = cin.tryRecv()
    let t_cout = cout.tryRecv()
    if not t_cin.dataAvailable and not t_cout.dataAvailable:
      if eval:
        cin.close()
        cout.close()
        break
      if is_async: await sleepAsync 100
      else: sleep 100
      continue
    let msgin {.inject.}: T = t_cin.msg
    let msgout {.inject.}: T = t_cout.msg
    template ifin(ib: untyped) =
      if not msgin.isNil:
        ib
    template ifout(ob: untyped) =
      if not msgout.isNil:
        ob
    block:
      lb




proc ezinit*[T](thread_name: string, worker: ThreadWorker, channel: var Channel[T]) =
  var ezt = EZThread()
  ezt.worker = worker
  ezt.channel = channel.addr
  ezt_registry[thread_name] = ezt
  channel.open()

proc ezadd*(thread_name: string, ezt: EZThread) =
  ezt_registry[thread_name] = ezt

proc ezstart*(ezt: EZThread) =
  ezt.thread.createThread ezt.worker, ezt.unsafeAddr

proc ezexit*(ezt: EZThread) =
  ezt.exit = true
  ezt.thread.joinThread()

proc ezsend*[T](ezt: EZThread, msg: T) =
  var channel = cast[ptr Channel[T]](ezt.channel)[]
  channel.send(msg)

proc ezexit* =
  for ezt in ezt_registry.values:
    ezt.ezexit()

proc ezget*(thread_name: string): EZThread =
  ezt_registry[thread_name]


type
  VoidThreadProc = proc() {.thread.}
template spawn_void_thread*(p: VoidThreadProc) =
  var t: Thread[void]
  t.createThread p


# another attempt at threading abstraction
import sharedtables
type
  ThreadGroup = ref object
    threads: seq[Thread[pointer]]
    id: uint32
  ThreadRegistry = SharedTable[int, seq[ThreadGroup]]
  PointerProc = proc (p: pointer) {.thread.}

var 
  thread_registry: ThreadRegistry 
  g_group_id: uint32 = 1
thread_registry.init()

proc `==`(a,b: ThreadGroup): bool = a.id == b.id
proc `[]`(tg: ThreadGroup, i: int): var Thread[pointer] = tg.threads[i]

proc ezspawn*(p: PointerProc, a: pointer = nil, amount: int = 1): ThreadGroup =
  ## spawn some amount of threads and adds them to a group
  {.cast(gcsafe).}:
    let id = getThreadId()
    discard thread_registry.hasKeyOrPut(id, @[])
    thread_registry.withValue(id, ts) do:
      var s = ts[]
      s.setLen(s.len + 1)
      s[^1] = ThreadGroup(id:g_group_id)
      inc g_group_id
      s[^1].threads.setLen(amount)
      for i in 0..amount - 1:
        s[^1][i].createThread(p, a)
      return s[^1]


proc ezsync*(tg: ThreadGroup = ThreadGroup()) =
  ## waits for all the threads spawned from the current thread
  {.cast(gcsafe).}:
    let id = getThreadId()
    thread_registry.withValue(id, ts) do:
      var s = ts[]
      if tg.id == 0:
        for stg in s:
          stg.threads.joinThreads()
        thread_registry.del id
      else:
        tg.threads.joinThreads()
        for i, stg in s:
          if stg == tg:
            s.del i

type
  EZWriteData* = (string, ptr Channel[string])

proc ez_write_thread*(p: pointer) {.thread.} =
  ## example:
  ## var data = newShared[(string, Channel[string])]()
  ## data[1].open()
  ## data[1].send "some line to be written to file"
  ## data[0] = "someFile.txt"
  ## var tg = ezspawn(ez_write_thread, data)
  ## tg.ezsync()
  ## deallocShared(data)
  var
    data = cast[ptr (string, ptr Channel[string])](p)
    file_name = data[][0]
    channel = data[][1]
    file = open(file_name, fmWrite)
  dbg file_name
  while true:
    let pek = channel[].peek()
    if pek < 1:
      if pek == -1:
        dbg "closing write thread", getThreadId()
        break
      sleep 1000
      continue
    let msg = channel[].recv()
    file.writeLine(msg)
  file.close()

proc ezchan*[T](chanType: typedesc[T]): ptr Channel[T] =
  result = newShared[Channel[T]]()
  result[].open()

proc close*[T](chanP: ptr Channel[T]) =
  chanP[].close()
  deallocShared(chanP)