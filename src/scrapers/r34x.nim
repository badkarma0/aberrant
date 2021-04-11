
import ../screep/util
import ../screep/base
import ../screep/scraper
import urlly
import json
import strformat
import strutils

const api = "https://rule34.xxx/index.php?page=dapi&s=post&q=index&json=1&limit=100"
scraper "r34x":
  let v_tags = v("arg1").replace(" ", "+")
  let v_max = v("max", "0").parseInt
  let v_full = v("full", "false").parseBool
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
      # echo urls
    # echo fc, pc, tc