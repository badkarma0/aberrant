import base
import strformat, termstyle, illwill_thread, sequtils
# LOGGING

type
  CommandKind = enum
    ckAddThead, ckDelThread
  MessageKind = enum
    mkMsg, mkCmd
  Message = ref object
    case kind: MessageKind
    of mkMsg: 
      tid: int
      content: string
    of mkCmd:
      case cmd_kind: CommandKind
      of ckAddThead: add_thread: int
      of ckDelThread: del_thread: int
var
  message_channel: Channel[Message]
  lt*: Thread[void]
  lt_do_debug* = false
  lt_do_verbose* = false
  lt_show_thread* = true
  lt_exit = false
  lt_tui = false


proc update_tui(iw: IllWill, threads: openArray[int], buffer: var TerminalBuffer, msg: Message) =
  for i in 0..threads.high:
    let tid = threads[i]
    if msg.tid == tid:
      # echo msg.content
      buffer.write(2, i * 3, $msg.tid, "::", msg.content)
  iw.display(buffer)

proc log_worker() {.thread.} =
  var 
    iw: IllWill
    tb: TerminalBuffer
    thread_registry: seq[int]
  if lt_tui:
    iw = newIllWill()
    iw.illwillInit(fullscreen=true)
    # setControlCHook(exit_tui)
    hideCursor()
    tb = newTerminalBuffer(terminalWidth(), terminalHeight())
  while true:
    let tried = message_channel.tryRecv()
    if not tried.dataAvailable:
      if lt_exit:
        if lt_tui:
          iw.illwillDeinit()
          showCursor()
        break
      continue
    let message = tried.msg
    if lt_tui:
      case message.kind:
      of mkCmd:
        case message.cmd_kind:
        of ckAddThead:
          thread_registry.add message.add_thread
        of ckDelThread:
          for i in 0..thread_registry.high - 1:
            if thread_registry[i] == message.del_thread:
              thread_registry.delete i
      of mkMsg:
        # echo message.content
        update_tui iw, thread_registry, tb, message
    else:
      if lt_show_thread:
        echo &"[{message.tid}]{message.content}"
      else:
        echo message.content


template ln(n: string) =
  message_channel.send(Message(kind: mkMsg, tid: getThreadId(), content: n))

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

template send_cmd(x_cmd_kind: CommandKind, key: untyped, value: untyped) =
  message_channel.send(Message(kind: mkCmd, cmd_kind: x_cmd_kind, key: value))

proc lag_del_thread*(id = getThreadId()) =
  if lt_tui:
    send_cmd ckDelThread, del_thread, id

proc lag_add_thread*(id = getThreadId()) =
  if lt_tui:
    send_cmd ckAddThead, add_thread, id



# proc exit_tui {.noconv.} =
#   illwillDeinit()
#   showCursor()
#   quit(0)

# proc init_tui {.async.} =

  # while true:
  #   let tried = message_channel.tryRecv()
  #   if not tried.dataAvailable:
  #     if lt_exit:
  #       break
  #     continue
  #   let message = tried.msg
    # echo message.content


proc init_logger*(tui = false) =
  lt_tui = tui
  message_channel.open()
  if lt_tui:
    echo "adding thread"
    lag_add_thread()
  createThread(lt, log_worker)

proc exit_logger* =
  lt_exit = true
  joinThread(lt)