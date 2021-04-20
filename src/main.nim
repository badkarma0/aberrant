import screep/base
import screep/util
import strformat, strutils
import scrapers/s_import
import termstyle
import times, options, urlly, nre

const version = "Aberrant v0.2.2"

proc get_scraper(scrapers: Scrapers, name: string): Option[Scraper] =
  for scraper in scrapers:
    if scraper.name == name:
      return some(scraper)

proc get_scraper_by_url(scrapers: Scrapers, url: string): Option[Scraper] =
  for scraper in scrapers:
    if scraper.rex.pattern == "": continue
    if url.find(scraper.rex).isSome:
      return some(scraper)

proc run(scraper: Scraper, url = "") =
  log &"Using Scraper: {scraper.name}"
  let st = cpuTime()
  scraper.srun(url.parseUrl)
  let ft = cpuTime() - st
  log &"Operation took {ft} seconds"

proc run_by_url(url: string) =
  var maybe_scraper = scrapers.get_scraper_by_url(url)
  if maybe_scraper.isSome:
    maybe_scraper.get.run(url)
  else:
    log "Could not match url to any scrapers"
    log "Using the default: mcrawl"
    maybe_scraper = scrapers.get_scraper("mcrawl")
    maybe_scraper.get.run(url)

proc main =
  ra "debug", false, help = "debug logging"
  ra "verbose", false, help = "verbose logging"
  arg v_help, "help", false, help = "show this menu"
  arg v_arg0, "arg0", help = &"scraper name or url\n scraper can be one of {scrapers}", req = true
  arg v_tui, "tui", false, help = &"use terminal user interface"
  arg v_file, "file", help = "read links from file"
  lt_do_debug = ga("debug", false)
  lt_do_verbose = ga("verbose", false)


  let a = red version
  # echo &"=== [ {a} ] ==="

  if v_help:
    print_help("some web scrapers\nur mom")
    return

  init_logger(v_tui)

  # if arg_starup_check():
  #   exit_logger()
  #   return

  if v_file != "":
    let file = open(v_file, fmRead)
    for line in file.lines:
      line.strip.run_by_url

  # dbg $pairs
  if v_arg0 == "":
    err &"Error scraper name or url required\n scraper can be one of {scrapers}"
    exit_logger()
    return

  var maybe_scraper = scrapers.get_scraper(v_arg0)
  if maybe_scraper.isSome:
    maybe_scraper.get.run()
  else:
    v_arg0.run_by_url()
  exit_logger()

main()