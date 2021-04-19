
import ../screep/scraper

let
  r1 = re"\/a\/(.*)$"

scraper "cyberdrop":
  match re"cyberdrop.me"
  arg v_a1, "arg1", help = "url"
  exec:
    if not xurl.empty: v_a1 = $xurl
    rcase v_a1:
      rof r1:
        hpage v_a1.parseUrl, captures[0].get:
          let items = data $$ ".image"
          for item in items:
            let video = item.attr "href"
            # log &"{s_found} {video}"
            # urls.add video
            video.download captures[0].get.get_dl_path / video.extractFilename, show_progress = true