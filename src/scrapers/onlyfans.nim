

import ../screep/scraper


scraper "onlyfans":
  match re"onlyfans.com"
  ra "arg1", help = "url"
  exec:
    var v_ar1 = ga"arg1"
    if not xurl.empty: v_ar1 = $xurl

    dbg v_ar1