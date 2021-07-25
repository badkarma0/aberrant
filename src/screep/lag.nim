import base
import strformat, termstyle, illwill_thread, sequtils, strutils
import tables
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
  Messages = seq[Message]
var
  message_channel: Channel[Message]
  lt*: Thread[void]
  lt_do_debug* = false
  lt_do_verbose* = false
  lt_do_trace* = false
  lt_show_thread* = true
  lt_exit = false
  lt_tui* = false


proc `[]`(msgs: Messages, tid: int): Message =
  for i in 0..msgs.high - 1:
    if tid == msgs[i].tid:
      return msgs[i]

proc update_or_add(msgs: var Messages, tid: int, msg: Message) =
  var i = 0
  for m in msgs:
    if tid == m.tid:
      msgs[i] = msg
      return
    i += 1
  msgs.add msg


proc log_worker() {.thread.} =
  var 
    iw: IllWill
    tb: TerminalBuffer
    thread_registry: seq[int]
    last_messages: Table[int, Message]
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
    let message: Message = tried.msg
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
        tb.clear()
      of mkMsg:
        tb.clear()
        if not (message.tid in thread_registry):
          break
        last_messages[message.tid] = message
        var i = 0
        for msg in last_messages.values:
          tb.write(0, i * 4, $msg.tid, "::", msg.content)
          tb.drawHorizLine(0, terminalWidth() - 2, i * 4 + 3)
          i += 1
        iw.display(tb)
    else:
      if lt_show_thread:
        echo &"[{message.tid}]{message.content}"
      else:
        echo message.content

proc ln(n: string)=
  message_channel.send(Message(kind: mkMsg, tid: getThreadId(), content: n))

template log*(msg: varargs[string, `$`]) =
  ln "[LOG] " & msg.join(" ")

template err*(msg: varargs[string, `$`]) =
  ln "[ERR] ".red & msg.join(" ")

template logv*(msg: varargs[string, `$`]) =
  if lt_do_verbose:
    ln "[LOG] " & msg.join(" ")

template dbg*(msgs: varargs[string, `$`]) =
  if lt_do_debug:
    var msg = msgs.join(" ")
    if lt_do_trace:
      var st = getStackTraceEntries()
      let s = st[st.len-2]
      msg &= italic("\n-> " & $s.filename & ":" & $s.line)
    ln "[DBG] ".yellow & msg

template dbg_exception* =
  var m = "Exception: ".red & $getCurrentException().name & "\n" 
  m &= getCurrentException().getStackTrace() & "\n"
  m &= getCurrentExceptionMsg() & "\n"
  dbg m

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