import strformat, strutils
import scrapers/s_import
import termstyle
import times, options, urlly, nre
import os, std.exitprocs
import terminal, asyncdispatch
import libscrape/rpc
import libscrape/base
import libscrape
# import gui/main
from libcurl import version

proc get_scraper(scrapers: Scrapers, name: string): Option[Scraper] =
  for scraper in scrapers.values:
    if scraper.name == name:
      return some(scraper)

proc get_scraper_by_url(scrapers: Scrapers, url: string): Option[Scraper] =
  for scraper in scrapers.values:
    if scraper.rex.pattern == "": continue
    if url.find(scraper.rex).isSome:
      return some(scraper)

proc run_by_url(url: string) =
  var maybe_scraper = scrapers.get_scraper_by_url(url)
  if maybe_scraper.isSome:
    maybe_scraper.get.run(url)
  else:
    log "Could not match url to any scrapers"
    log "Using the default: mcrawl"
    maybe_scraper = scrapers.get_scraper("mcrawl")
    maybe_scraper.get.run(url)

proc cleanup =
  exit_logger()
  resetAttributes()

proc main =
  ra "debug", false, help = "debug logging"
  ra "verbose", false, help = "verbose logging"
  ra "trace", false, help = "show trace with debug logging"
  arg v_help, "help", false, help = "show this menu"
  arg v_version, "version", false, help = "print version"
  arg v_arg0, "arg0", help = &"scraper name or url\n scraper can be one of {scrapers}", req = true
  arg v_tui, "tui", false, help = &"use terminal user interface"
  arg v_file, "file", help = "read links from file"
  arg v_dl, "dl", help = "download a file"
  arg v_daemon, "daemon", false, help = "run as a daemon"
  arg v_gui, "gui", false, help = "run with a gui"
  lt_do_debug = ga("debug", false)
  lt_do_verbose = ga("verbose", false)
  lt_do_trace = ga("trace", false)

  let a = red base.version

  if v_version:
    when defined(release):
      echo base.version & " (release)"
    else:
      echo base.version & " (debug)"
    echo "Compiled with Nim v" & NimVersion
    echo "Compiled at " & CompileDate & "/" & CompileTime
    echo libcurl.version()
    return
  
  if v_help:
    var help = ""
    help &= "USAGE:" &
    "\naberrant [SCRAPER_NAME] [SCRAPER_ARGS]" &
    "\naberrant [URL]" 
    var cats: seq[string]
    for k in scrapers.keys:
      cats.add k
    print_help(cats, &"=== [ {a} ] ===", help)
    return

  init_logger(v_tui)
  # lt_basic = true
  # if arg_starup_check():
  #   exit_logger()
  #   return

  if v_gui:
    dbg "starting gui on main thread"
    # start_gui()
    return

  if v_daemon:
    start_rpc()
    runForever()
    return

  if v_dl != "":
    makeDownload(v_dl, v_dl.extractFilename, overwrite=true, show_progress = true).download
    return

  if v_file != "":
    let file = open(v_file, fmRead)
    for line in file.lines:
      line.strip.run_by_url

  # dbg $pairs
  if v_arg0 == "":
    err &"Error scraper name or url required\n scraper can be one of {scrapers}"
    return

  var maybe_scraper = scrapers.get_scraper(v_arg0)
  try:
    if maybe_scraper.isSome:
      maybe_scraper.get.run()
    else:
      v_arg0.run_by_url()
  except:
    cleanup()
    echo "FATAL: " & $getCurrentException().name 
    echo getCurrentException().getStackTrace()
    echo getCurrentExceptionMsg()


when isMainModule:
  # setControlCHook()
  addExitProc(cleanup)
  main()