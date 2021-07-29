
import tables, os

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


template ezloop*[T](cin,cout: Channel[T], eval: untyped, lb: untyped) =
  while true:
    let t_cin = cin.tryRecv()
    let t_cout = cout.tryRecv()
    if not t_cin.dataAvailable and not t_cout.dataAvailable:
      if eval:
        cin.close()
        cout.close()
        break
      sleep 100
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
proc spawn_void_thread*(p: VoidThreadProc): Thread[void] =
  result.createThread p