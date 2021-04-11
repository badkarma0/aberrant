import screep/base
import screep/util
import parseopt
import strformat
import scrapers/s_import
import termstyle
import times

const version = "Aberrant v0.1.1"
verbose = true

proc main =
  let a = red version
  echo &"=== [ {a} ] ==="
  var pairs: seq[KVPair] = @[]
  var target: string = ""
  var ac = 0
  for kind, key, val in getopt():
    case kind:
    of cmdArgument:
      if target.len == 0:
        target = key
      else:
        pairs.add (key: &"arg{ac}", value: key)
      ac += 1
    of cmdLongOption, cmdShortOption:
      pairs.add (key: key, value: val)
    of cmdEnd:
      break
  dbg $pairs
  if target == "":
    err &"scraper name required, can be one of {scrapers}"
    exit_logger()
    return
  log &"Scraper: {target}"
  for scraper in scrapers:
    if scraper.name == target:
      let st = cpuTime()
      scraper.srun(pairs)
      let ft = cpuTime() - st
      log &"Operation took {ft} seconds"
  exit_logger()


main()