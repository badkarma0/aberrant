# parseopt wrapper
import termstyle, strformat, strutils, parseopt, algorithm, sequtils, sugar
import macros, json, tables
import strtabs
type
  Arg* = ref object
    name*: string
    help*: string
    kind*: string
    req*: bool
    smod*: string
    def: string
  Args = seq[Arg]
  ArgStore* = StringTableRef
var r_args: Args



proc print(arg: Arg) =
  var 
    rs = ""
    d = ""
  if arg.req:
    rs = "*"
  if arg.def != "":
    d = arg.def
  echo &"{arg.name}\t\t{rs}\t {arg.kind}\t\t{d}\t\t{arg.help}"

proc print_mod(s: string) =
  echo bold negative &"\n {s}"

proc print_help*(cats: openArray[string], title,desc: string) =
  # echo box(&" {desc} ", '0', cc = termCyan & termNegative, sc = termNegative)
  echo title
  echo ""
  for line in desc.split('\n'):
    echo &" {line}"
  echo ""
  echo red bold &"name\t\trequired  type\t\tdefault\t\t help"
  "global".print_mod
  for arg in r_args:
    if arg.smod == "":
      arg.print
  for cat in cats:
    cat.print_mod
    for arg in r_args:
      if arg.smod == cat:
        arg.print

proc get_args_as_json*: JsonNode =
  %*r_args

proc parse_args*(args: string = ""): ArgStore =
  result = newStringTable()
  var ac = 0
  var opp = initOptParser(args) 
  for kind, key, val in opp.getopt:
    case kind:
    of cmdArgument:
      result[&"arg{ac}"] = key
      ac += 1
    of cmdLongOption, cmdShortOption:
      if val == "":
        result[key] = "true"
      else:
        result[key] = val
    of cmdEnd:
      break

let gArgStore*: ArgStore = parse_args()


proc arg_starup_check*: bool =
  r_args.sort do (a,b: Arg) -> int:
    a.name.cmp b.name
  for arg in r_args:
    let name = arg.name
    if gArgStore.hasKey(name):
      continue
    if arg.req:
      echo &"Error Missing arg: {arg.name}, here is the relevant help"
      arg.smod.print_mod
      arg.print
      return true
  return false

template loa(ags: ArgStore, name: string, def: typed, body: untyped) =
  {.cast(gcsafe).}:
    try:
      var ar {.inject.} = ags[name]
      block:
        body
    except KeyError:
      discard
    except Exception:
      echo &"{name} has wrong type"
      echo getCurrentExceptionMsg()
    return def


proc ga*[T](name: string, def: T = ""): T =
  loa gArgStore, name, def:
    return ar.parseJson.to T
proc ga*(name: string, def = ""): string =
  loa gArgStore, name, def:
    return ar
proc ga*(name: string, def: bool): bool =
  loa gArgStore, name, def:
    return ar.parseBool
proc ga*(name: string, def: int): int =
  loa gArgStore, name, def:
    return ar.parseInt
proc ga*(name: string, def: float): float =
  loa gArgStore, name, def:
    return ar.parseFloat

# proc get*[T](ags: ArgStore, name: string, def: T): T =
#   loa ags, name, def:
#     return ags[name].parseJson.to T
proc get*(ags: ArgStore, name: string, def = ""): string =
  loa ags, name, def:
    return ar
proc get*(ags: ArgStore, name: string, def: bool): bool =
  loa ags, name, def:
    return ar.parseBool
proc get*(ags: ArgStore, name: string, def: int): int =
  loa ags, name, def:
    return ar.parseInt
proc get*(ags: ArgStore, name: string, def: float): float =
  loa ags, name, def:
    return ar.parseFloat
  
  
proc add_arg(name, kind, help, smod: string, req: bool, def: string) =
  r_args.add Arg(name: name, help: help, kind: kind, req: req, smod: smod, def: def)

template ra*(name: string, def: typed = "", help = "", req = false, smod = "") =
  add_arg name, $typeof(def), help, smod, req, $def

template arg*(arg_name: untyped, name: string, def: typed = "", help = "", req = false, smod = "") =
  ra name, def, help, req, smod
  var `arg_name` {.inject.} = ga(name, def)

