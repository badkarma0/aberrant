import base
import strformat, termstyle
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