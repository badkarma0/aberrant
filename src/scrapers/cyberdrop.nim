
import ../libscrape
import nre
const
  top_url = "https://cdn.cyberdrop.me/hits/"
  base_url = "https://cyberdrop.me/"


scraper "cyberdrop":
  match re"cyberdrop.me"
  ra "arg1", help = "url"
  exec:
    let
      r1 = re"\/a\/(.*)$"
      r2 = re"top"
    var v_a1 = "arg1".ga
    if not xurl.empty: v_a1 = $xurl

    proc get_album(id: string) =
      let url = &"{base_url}a/{id}"
      log &"{s_found} {url}"
      hpage url.parseUrl, "":
        let items = data $$ ".image"
        let title = (data $ "#title").innerText.strip
        let base_path = &"{id}_{title}"
        for item in items:
          let video = item.attr "href"
          # log &"{s_found} {video}"
          # urls.add video
          video.download base_path.get_dl_path / video.extractFilename, show_progress = true

    rcase v_a1:
      rof r1:
        get_album captures[0].get
      rof r2:
        hpage top_url.parseUrl, "":
          for anchor in data $$ "a":
            let href = anchor.attr("href")
            rcase href:
              rof r1:
                get_album captures[0].get
              
              
            
