import re
import strutils
import math
import puppy
import xmltree
import urlly
import os
import strformat
import ../screep/util
import ../screep/scraper

const site = "http://cfake.com/"
const id = "cfake"

scraper id:
  let v_name = v("arg1")
  if v_name.len == 0:
    echo "error name is empty"
    return
  let doc = fetchHtml(parseUrl(site & "picture?libelle=" & v_name))
  let a = doc $ ".name_vignette a"
  if a.innerText != v_name:
    echo &"inccorect name {v_name}, closest is {a.innerText}"
    return

  let url = parseUrl(site) / a.attr("href")
  let path = "./test" / v_name

  echo &"Found {v_name} @ {url}"
  echo &"Downloading to: {path}"

  let res = fetch($url)
  let r1 = re"thumbs"
  let r2 = re"about.([0-9]*).for"
  var matches = [""]
  discard res.find(r2, matches)

  let total = matches[0].parseInt
  let pageCount = ceil(total / 30).toInt

  echo &"Images: {total}"
  echo &"Pages: {pageCount}"

  pages(0, pageCount):
    hpage(url / &"p{i * 30}", v_name):
      for el in data $$ ".thumb_show ~ a img":
        let img = site & el.attr("src").replace(r1,"photos")
        urls.add(img)