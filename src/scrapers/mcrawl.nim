import ../screep/scraper
import ../screep/util

scraper "mcrawl":
  let v_start_url = ga("arg1")
  if v_start_url == "":
    err "please provide an url"
    return


    