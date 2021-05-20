

import ../screep/scraper


scraper "onlyfans":
  match re"onlyfans.com"
  arg v_ar1, "arg1", help = "url"
  exec:
    if not xurl.empty: v_ar1 = $xurl

    dbg v_ar1