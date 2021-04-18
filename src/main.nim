import screep/base
import screep/util
import strformat
import scrapers/s_import
import termstyle
import times, options, urlly, nre

const version = "Aberrant v0.2.0"

proc get_scraper(scrapers: Scrapers, name: string): Option[Scraper] =
  for scraper in scrapers:
    if scraper.name == name:
      return some(scraper)

proc get_scraper_by_url(scrapers: Scrapers, url: string): Option[Scraper] =
  for scraper in scrapers:
    if url.find(scraper.rex).isSome:
      return some(scraper)

proc run(scraper: Scraper, url = "") =
  log &"Using Scraper: {scraper.name}"
  let st = cpuTime()
  scraper.srun(url.parseUrl)
  let ft = cpuTime() - st
  log &"Operation took {ft} seconds"

proc main =
  ra "debug", false, help = "debug logging"
  ra "verbose", false, help = "verbose logging"
  arg v_help, "help", false, help = "show this menu"
  arg v_arg0, "arg0", help = &"scraper name or url\n scraper can be one of {scrapers}", req = true
  arg v_tui, "tui", false, help = &"use terminal user interface"
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
  
  # dbg $pairs
  if v_arg0 == "":
    err &"Error scraper name or url required\n scraper can be one of {scrapers}"
    exit_logger()
    return

  var maybe_scraper = scrapers.get_scraper(v_arg0)
  if maybe_scraper.isSome:
    maybe_scraper.get.run()
  else:
    maybe_scraper = scrapers.get_scraper_by_url(v_arg0)
    if maybe_scraper.isSome:
      maybe_scraper.get.run(v_arg0)
    else:
      log "Could not match url to any scrapers"
      log "Using the default: mcrawl"
      maybe_scraper = scrapers.get_scraper("mcrawl")
      maybe_scraper.get.run(v_arg0)
  echo "dying"
  exit_logger()

main()