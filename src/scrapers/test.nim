import ../libscrape

import threadpool

proc www =
  while true:
    sleep 1000
    log "sleeping 1 sec"

scraper "test":
  exec:
    for _ in 0..10:
      spawn www()
    sync()