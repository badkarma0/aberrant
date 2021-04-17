import ../screep/scraper


let
  video_url_base = "https://www.pornhub.com/view_video.php".parseUrl
  r1 = re"(?x)""text"":.*?""(.*?)"".*?""url"":.*?""(.*?)"""
  r_viewkey = re"(?<=\W|^)[0-9a-z]{15}(?=\W|$)"

scraper "pornhub":
  arg v_url, "arg1", req = true, help = "a string containing a viewkey, can be video url"
  exec:
    
    var viewkey = ""
    if v_url.contains r_viewkey:
      viewkey = v_url.find(r_viewkey).get.match
      video_url_base.query["viewkey"] = viewkey
      v_url = $video_url_base
      log &"{s_found} viewkey: {viewkey}"
    else:
      err &"no view key found in {v_url}"
      return
    hpage v_url.parseUrl, "":
      let script = data $ "#player script"
      var p_size = 0
      var p_video = ""
      for m in script.innerText.findIter r1:
        let caps = m.captures.toSeq
        let size = caps[0].get.replace("p","").parseInt
        let video = caps[1].get.replace("\\", "")
        if size > p_size and video != "":
          p_size = size
          p_video = video
      log &"{s_found} video: {p_size} :: {p_video}"
      if p_video != "":
        if viewkey != "":
          download makeDownload(p_video, getDlRoot() / "pornhub" / viewkey & ".mp4")  