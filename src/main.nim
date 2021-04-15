import screep/base
import screep/util
import strformat
import scrapers/s_import
import termstyle
import times

const version = "Aberrant v0.1.4"

proc main =
  lt_do_debug = ga("debug", false)
  lt_do_verbose = ga("verbose", false)
  let a = red version
  echo &"=== [ {a} ] ==="
  # dbg $pairs
  let target = ga("arg0", "mcrawl")
  if target == "":
    err &"scraper name required, can be one of {scrapers} or an url"
    exit_logger()
    return
  log &"Scraper: {target}"
  for scraper in scrapers:
    if scraper.name == target:
      let st = cpuTime()
      scraper.srun()
      let ft = cpuTime() - st
      log &"Operation took {ft} seconds"
  exit_logger()

main()