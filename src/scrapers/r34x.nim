
import ../screep/util
import ../screep/base
import ../screep/scraper
import urlly
import json
import strformat
import strutils

const api = "https://rule34.xxx/index.php?page=dapi&s=post&q=index&json=1&limit=100"


scraper "r34x":
  ra "arg1", help = "\"some tags\" or some+tags", req = true
  ra "max", 100
  ra "full", false
  exec:
    var 
      v_tags = ga"arg1"
      v_max = "max".ga 100
      v_full = "full".ga false
    v_tags = v_tags.replace(" ", "+")
    # let v_tags = ga("arg1").replace(" ", "+")
    # let v_max = ga("max", 100)
    # let v_full = ga("full", false)
    if v_tags == "":
      err "please specify some tags"
      return
    
    let url = parseUrl(api)
    url.query["tags"] = v_tags
    
    log &"URL : {url}"

    var fc = 100
    var pc = 0
    var tc = 0
    while fc == 100 and tc < v_max:
      url.query["p"] = $pc
      jpage url, v_tags:
        fc = data.getElems().len
        tc += fc
        pc += 1
        for elem in data.getElems():
          urls.add(elem[if v_full: "file_url" else: "sample_url"].getStr())
        # dbg $urls
      # echo fc, pc, tc