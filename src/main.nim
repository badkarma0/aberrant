import screep/base
import screep/util
import strformat
import scrapers/s_import
import termstyle
import times, options, urlly, nre

const version = "Aberrant v0.1.6"

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
  ra "debug", false, xhelp = "debug logging"
  ra "verbose", false, xhelp = "verbose logging"
  arg v_help, "help", false, help = "show this menu"
  
  lt_do_debug = ga("debug", false)
  lt_do_verbose = ga("verbose", false)

  let a = red version
  echo &"=== [ {a} ] ==="

  if v_help:
    print_help("some web scrapers\nsome new line")
    exit_logger()
    return

  # dbg $pairs
  let target = ga("arg0")
  if target == "":
    err &"scraper name or url required\n scraper can be one of {scrapers}"
    exit_logger()
    return

  var maybe_scraper = scrapers.get_scraper(target)
  if maybe_scraper.isSome:
    maybe_scraper.get.run()
  else:
    maybe_scraper = scrapers.get_scraper_by_url(target)
    if maybe_scraper.isSome:
      maybe_scraper.get.run(target)
    else:
      log "Could not match url to any scrapers"
      log "Using the default: mcrawl"
      maybe_scraper = scrapers.get_scraper("mcrawl")
      maybe_scraper.get.run(target)
  exit_logger()

main()