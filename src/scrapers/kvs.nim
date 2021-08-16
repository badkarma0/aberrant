
import ../libscrape
import math, nre

const hash_range = 16
func calc_seed(lc: string):string =
  var c = lc.replace("$", "").replace("0", "1")
  # debugEcho "c = " & c
  var 
    j = toInt floor c.len / 2
  # debugEcho "j = " & $j
  var
    k = c.substr(0, j).parseInt
  # debugEcho "k = " & $k
  var
    l = c.substr(j).parseInt
    g = abs(l - k)
    fi = $((g + g) * 2)
    n = toInt hash_range / 2 + 2
  # debugEcho l, " ", g, " ", fi, " ",n
  # debugEcho c
  for i in 0..j:
    for h in 1..4:
      var
        x1 =  parseInt($lc[i+h])
        x2 = parseInt($fi[i])
        il = x1 + x2
      # debugEcho &"{i} {h} {x1} {x2} {il}" 
      if il >= n:
        il -= n
      result &= $il
  # debugEcho result

func decrypt_hash(hs,lc:string): string =
  var 
    hash = hs.substr(0, hash_range * 2 - 1)
    tail = hs.substr(hash_range * 2)
    seed = lc.calc_seed()
  var k = hash.len - 1
  while k >= 0:
    var l = k
    var em = ""
    for m in k..seed.len-1:
      l += parseInt $seed[m]
    while l >= hash.len:
      l -= hash.len
    for o in 0..hash.len-1:
      if o == k:
        em &= hash[l]
      elif o == l:
        em &= hash[k]
      else:
        em &= hash[o]
    hash = em
    k -= 1
  hash & tail



# works on all Kernel Video Sharing (KVS) CMS sites (maybe)
scraper "kvs":
  ra "arg1", req = true, help = "an url to a kvs site"
  exec:
    let 
      r1 = re"video.*?url.*?:.'function/0/(.*?)'"
      r2 = re"(.*)\/.*?$"
      r3 = re"rnd: '(.*?)'"
      r4 = re"license_code: '(.*?)'"
    var v_url = ga"arg1"
    if v_url == "":
      err "no url provided"
      return
    hpage parseUrl(v_url), "test":
      header "referer", $v_url
      let scripts = data $$ ".player-holder script"
      let ss = $scripts[1]
      var videos: seq[Url]
      var rnd = ss.find(r3).get.captures[0]
      var lc = ss.find(r4).get.captures[0]
      rnd = "1626886807295"
      for m in ss.findIter r1:
        let video = m.captures[0].parseUrl
        var parts = video.path.split("/")

        var uhash = parts[3].decrypt_hash lc
        parts[3] = uhash
        video.path = parts.join("/").replace(re"\/$", "")
        # video.query["rnd"] = $rnd 
        dbg video
        let dl = make_download($video, getDlRoot() / "kvs" / video.path.extractFilename, true)
        dl.headers = headers
        dl.download
        break
      
      # echo videos