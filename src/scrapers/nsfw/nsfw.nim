

import ../../libscrape, nre


scraper "sexyegirls":
  match re"sexy-egirls.com/albums"
  exec:
    get_url()
    let album_name = find($v_start_url, re"albums/(.*)(/|$)").get.captures[0]
    hpage v_start_url, "":
      var api_url = find(data.innerText, "url: \"(.*?action=album.*?)\"".re).get.captures[0].parseUrl
      jpage api_url, album_name:
        if data["success"].getBool:
          for file in data["files"].getElems:
            urls.add file["src"].getStr
        else:
          err "failed to do request to ", api_url  