import ../screep/scraper



# proc download_video(viewkey: string) =
  

scraper "pornhub":
  ra "arg1", req = true, help = "a string containing a viewkey, can be video url"
  exec:
    
    let
      url_base = "https://www.pornhub.com/".parseUrl
      video_url_base = url_base / "view_video.php"
      r1 = re"(?x)""text"":.*?""(.*?)"".*?""url"":.*?""(.*?)"""
      r2 = re"Showing (\d*)-(\d*) of (\d*)"
      r_viewkey = re"(?<=\W|^)([0-9a-z]{15})(?=\W|$)"
      r_model = re"(pornstar|model)\/(.*?)(?=\W|$)"
    var v_url = ga"arg1"

    proc download_video(viewkey: string) =
      let url = video_url_base
      url.query["viewkey"] = viewkey
      hpage url, "":
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
          download makeDownload(p_video, getDlRoot() / "pornhub" / viewkey & ".mp4")

    proc download_model(kind_model: string) =
      var
        url = url_base / kind_model / "videos"
        has_next = true
      while has_next:
        hpage url, "":
          log magenta $url
          let 
            most_recent_videos = data $$ "#mostRecentVideosSection .videoBox"
            info = (data $ ".showingInfo").innerText.find(r2).get.captures.toSeq
            next_page_button = data $ ".page_next a"
            min_videos = info[0].get
            max_videos = info[1].get
            total_videos = info[2].get
          # log &"Getting {min_videos}-{max_videos}/{total_videos}"
          for elem in most_recent_videos:
            download_video elem.attr("data-video-vkey")
          if not next_page_button.isNil:
            url = url / next_page_button.attr("href")
          else:
            has_next = false
        


    rcase v_url:
      rof r_viewkey:
        let viewkey = captures[0].get
        log &"{s_found} viewkey: {viewkey}"
        download_video viewkey
      rof r_model:
        let model = captures[1].get
        let kind = captures[0].get
        log &"{s_found} model: {model} kind: {kind}"
        download_model &"{kind}/{model}/"

