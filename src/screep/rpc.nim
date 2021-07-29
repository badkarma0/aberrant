import scraper
import asyncdispatch, asynchttpserver, ws
import strutils
type
  RPCMSG = ref object
    msg: string
    source: WebSocket

const ws_port = 8238

var 
  in_channel: Channel[RPCMSG]
  out_channel: Channel[RPCMSG]
  connections: seq[WebSocket]

in_channel.open()
out_channel.open()

var p_s = scrapers.unsafeAddr
var p_connections = connections.unsafeAddr

func m(s:string, ws: WebSocket = nil): RPCMSG =
  RPCMSG(msg:s,source:ws)

proc write_out(m: string) =
  out_channel.send(m.m)

proc cb(req: asynchttpserver.Request) {.async, gcsafe.} =
  try:
    var ws = await newWebSocket(req)
    p_connections[].add ws
    while ws.readyState == Open:
      let packet = await ws.receiveStrPacket()
      in_channel.send(m(packet, ws))
  except:
    err getCurrentExceptionMsg()

proc ws_worker() {.thread.} =
  var server = newAsyncHttpServer()
  waitFor server.serve(Port(ws_port), cb)

func packet(data: openArray[string]): JsonNode =
  return

proc rpc_worker(ezts: pointer) {.thread.} =
  log &"~~~ INIT RPC THREAD on localhost:{ws_port} ~~~"
  var ezt = cast[ptr EZThread](ezts)[]
  var scrapers: Scrapers = p_s[]
  echo "before set wp"
  lag_set_write_proc write_out
  echo "still not crashed"
  try:
    ezloop in_channel, out_channel, ezt.exit:
      ifin:
        log "<=", msgin.msg
        var c = msgin.msg.split(":")
        if c[0] == "exec":
          var scraper = scrapers[c[1]]
          if scraper.isNil:
            asyncCheck msgin.source.send("err:exec:" & c[1])
          scraper.run(c[2])
      ifout:
        log "=>", msgout.msg
  except:
    dbg_exception()

var rpc_ezt = EZThread()
rpc_ezt.worker = rpc_worker
"rpc".ezadd rpc_ezt

discard ws_worker.spawn_void_thread
