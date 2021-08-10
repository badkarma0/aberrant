import scraper
import asyncdispatch, asynchttpserver, ws
import strutils
type
  RPCMSG = ref object
    msg: string
    source: WebSocket
  ClientServerMsg = ref object
    exec,id,notif: Option[string]
    params: Option[seq[string]]
  ServerClientMsg = ref object
    result,error,id,notif:string

const ws_port = 8238

var 
  in_channel: Channel[RPCMSG]
  out_channel: Channel[RPCMSG]
  connections: seq[WebSocket]
  pcon = connections.addr
in_channel.open()
out_channel.open()


proc unpack(s: string): ClientServerMsg = s.parseJson.to ClientServerMsg

proc pack(s: ServerClientMsg): string = $(%*s)

func rpcmsg(s:string, ws: WebSocket = nil): RPCMSG =
  RPCMSG(msg:s,source:ws)

proc write_out(m: string) =
  out_channel.send(rpcmsg m)

proc cb(req: asynchttpserver.Request) {.async, gcsafe.} =
  try:
    var ws = await newWebSocket(req)
    pcon[].add ws
    asyncCheck ws.send ServerClientMsg(notif:"connected").pack
    while ws.readyState == Open:
      let packet = await ws.receiveStrPacket()
      in_channel.send(rpcmsg(packet, ws))
  except:
    echo getCurrentExceptionMsg()

proc ws_worker() {.async.} =
  var server = newAsyncHttpServer()
  await server.serve(Port(ws_port), cb)

proc errp(err,id:string): string =
  var m: ServerClientMsg
  m.error = err
  m.id = id
  m.pack

proc rpc_worker() {.async.} =
  var e = false;
  var is_async = true;
  ezloop in_channel, out_channel, e, is_async:
    ifin:
      echo "<= ", msgin.msg
      var msg = msgin.msg.unpack
      if msg.id.isNone:
        msg.id = "NOID".some
      let id = msg.id.get
      proc result(s: string) =
        echo &"=> result {id} : {s}"
        asyncCheck msgin.source.send ServerClientMsg(id:id, result:s).pack
      if msg.exec.isSome:
        var exec = msg.exec.get
        if exec == "rpc_get_scrapers":
          result $get_args_as_json()
        elif scrapers.contains exec:
          var scraper = scrapers[exec]
          if msg.params.isSome and msg.params.get.high > -1: 
            scraper.run(msg.params.get[0])
          else:
            scraper.run()
        else:
          err exec & " not found : " & id
    ifout:
      echo "=> ", msgout.msg
      var msg = ServerClientMsg()
      msg.notif = msgout.msg
      var pmsg = msg.pack
      for ws in connections:
        if ws.readyState == Open:
          asyncCheck ws.send pmsg

proc start_rpc* =
  log &"~~~ INIT RPC on localhost:{ws_port} ~~~"
  lag_set_write_proc write_out
  asyncCheck rpc_worker()
  asyncCheck ws_worker()