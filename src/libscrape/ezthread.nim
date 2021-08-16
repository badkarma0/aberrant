
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
  ThreadRegistry = SharedTable[int, seq[Thread[pointer]]]
  PointerProc = proc (p: pointer) {.thread.}

var thread_registry: ThreadRegistry 
thread_registry.init()


proc ezspawn*(amount: int, p: PointerProc, a: pointer) =
  {.cast(gcsafe).}:
    let id = getThreadId()
    # var thread = newShared[Thread[pointer]]()
    # thread[].createThread(p, a)
    discard thread_registry.hasKeyOrPut(id, @[])
    thread_registry.withValue(id, ts) do:
      ts[].setLen amount
      for i in 0..amount-1:
        ts[][i].createThread(p, a)


proc ezsync* =
  ## waits for all the threads spawned from the current thread
  {.cast(gcsafe).}:
    let id = getThreadId()
    thread_registry.withValue(id, ts) do:
      ts[].joinThreads()
      thread_registry.del id