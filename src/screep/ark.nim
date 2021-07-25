# parseopt wrapper
import base, lag
import termstyle, strformat, strutils, parseopt, algorithm, sequtils, sugar

type
  Arg* = ref object
    name*: string
    help*: string
    kind*: string
    req*: bool
    smod*: string
  Args = seq[Arg]

var r_args: Args

proc print(arg: Arg) =
  var 
    rs = ""
    d = ""
  if arg.req:
    rs = "*"
  # if not arg.def.isNil:
  #   d = " (default: " & $arg.def & ")"
  echo &"{arg.name}\t\t{rs}\t {arg.kind}\t\t{arg.help}{d}"

proc print_mod(s: string) =
  echo bold negative &"\n {s}"

proc print_help*(desc: string) =
  # echo box(&" {desc} ", '0', cc = termCyan & termNegative, sc = termNegative)
  echo ""
  for line in desc.split('\n'):
    echo &" {line}"
  echo ""
  echo red bold &"name\t\trequired  type\t\t help"
  "global".print_mod
  for arg in r_args:
    if arg.smod == "":
      arg.print
  for scraper in scrapers:
    scraper.name.print_mod
    for arg in r_args:
      if arg.smod == scraper.name:
        arg.print

proc parse(): seq[KVPair] =
  var args: seq[KVPair] = @[]
  var ac = 0
  for kind, key, val in getopt():
    case kind:
    of cmdArgument:
      args.add KVPair(key: &"arg{ac}", value: key)
      ac += 1
    of cmdLongOption, cmdShortOption:
      if val == "":
        args.add KVPair(key: key, value: "true")
      else:
        args.add KVPair(key: key, value: val)
    of cmdEnd:
      break
  args


proc arg_starup_check*: bool =
  let parsed = parse()
  r_args.sort do (a,b: Arg) -> int:
    a.name.cmp b.name
  for arg in r_args:
    let name = arg.name
    if parsed.any((a) => a.key == name):
      continue
    if arg.req:
      echo &"Error Missing arg: {arg.name}, here is the relevant help"
      arg.smod.print_mod
      arg.print
      return true
  return false

template loa(name: string, def: typed, body: untyped) =
  for ar {.inject.} in parse():
    if ar.key == name:
      try:
        block:
          body
        break
      except Exception:
        err &"{name} has wrong type"

  return def

proc ga*(name: string, def = ""): string =
  loa name, def:
    return ar.value
proc ga*(name: string, def: bool): bool =
  loa name, def:
    return ar.value.parseBool
proc ga*(name: string, def: int): int =
  loa name, def:
    return ar.value.parseInt
proc ga*(name: string, def: float): float =
  loa name, def:
    return ar.value.parseFloat

proc add_arg(name, kind, help, smod: string, req: bool) =
  r_args.add Arg(name: name, help: help, kind: kind, req: req, smod: smod)

template ra*(name: string, def: typed = "", help = "", req = false, smod = "") =
  add_arg name, $typeof(def), help, smod, req

template arg*(arg_name: untyped, name: string, def: typed = "", help = "", req = false, smod = "") =
  ra name, def, help, req, smod
  var `arg_name` {.inject.} = ga(name, def)
