import ../screep/scraper

const base = "http://imgbox.com/g"

scraper "imgbox":
  match base.re
  ra "arg1", help = "url"
  exec:
    let 
      r1 = re"g/(.*)"
    var v_ar1 = "arg1".ga
    if not xurl.empty: v_ar1 = $xurl
    rcase v_ar1:
      rof r1:
        let gid = captures[0].get
        let nurl = base & "/" & gid
        log nurl
        hpage nurl.parseUrl, gid:
          for el in data $$ "#gallery-view-content img":
            let thumb = el.attr("src")
            urls.add thumb.replace("thumbs", "images").replace("_b.", "_o.")