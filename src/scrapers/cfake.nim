import strutils
import math
import xmltree
import strformat
import ../libscrape

const site = "http://cfake.com/"

scraper "cfake":
  match re(site & "picture")
  # ra "arg1", help="name of person", req = true
  ra "arg1", help = "name of person", req = true
  exec:
    let 
      r1 = re"thumbs"
      r2 = re"about.([0-9]*).for"
      r3 = re"picture/(.*?)/"
    var v_name = "arg1".ga
    var target = parseUrl("")
    if v_name == "":
      if not xurl.empty:
        let match = ($xurl).find r3
        target = xurl
        v_name = match.get.captures[0]
      else:
        err "name can not be empty"
        return
    if target.empty:  
      let doc = fetchHtml(parseUrl(site & "picture?libelle=" & v_name))
      let a = doc $ ".name_vignette a"
      if a.innerText != v_name:
        err &"inccorect name {v_name}, closest is {a.innerText}"
        return

      target = parseUrl(site) / a.attr("href")

    log &"Found {v_name} @ {target}"

    let res = fetch($target)

    let match = res.find(r2)

    var total = 0
    if match.isSome:
      total = match.get.captures[0].parseInt
    if total == 0:
      err &"found no images"
      return    
    let pageCount = ceil(total / 30).toInt

    log &"Images: {total}"
    log &"Pages: {pageCount}"

    pages(0, pageCount):
      hpage(target / &"p{i * 30}", v_name):
        for el in data $$ ".thumb_show ~ a img":
          let img = site & el.attr("src").replace(r1,"photos")
          urls.add(img)