

import ../libscrape

scraper "reddit":
  ra "arg1", req = true, help = "a reddit url"
  exec:
    var v_url = ga"arg1"
    if v_url == "":
      err "url cant be empty"
      return
    
    var after: string
    var base_url = v_url.parseUrl
    while true:
      if after != "":
        base_url.query["after"] = after
      log &"getting after {after}"
      jpage base_url, "test":
        let items = data["data"]["children"]
        after = data["data"]["after"].getStr
        if not items.isNil:
          for item in items:
            if item["data"]["post_hint"].getStr == "image":
              let url = item["data"]["url"].getStr 
              urls.add url