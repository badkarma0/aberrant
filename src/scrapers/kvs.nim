
import ../screep/util
import ../screep/scraper
import nre, times, urlly, os

let 
  r1 = re"video.*?url:.'(.*?)'"
  r2 = re"(.*)\/.*?$"
# works on all KVS CMS sites (maybe)
scraper "kvs":
  arg v_url, "arg1", req = true, help = "an url to a kvs site"
  exec:
    if v_url == "":
      err "no url provided"
      return
    
    hpage parseUrl(v_url), "test":
      header "referer", $v_url
      let scripts = data $$ ".player-holder script"
      let ss = $scripts[1]
      var videos: seq[Url]

      for m in ss.findIter r1:
        let video = m.captures.toSeq[0].get
        echo video
        let dl = makeDownload(video, getDlRoot() / "kvs" / video.replace(r2, "$1").extractFilename, true)
        dl.headers = headers
        dl.download
      
      # echo videos