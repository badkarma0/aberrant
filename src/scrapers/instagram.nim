
import ../screep/scraper
import times

const
  hash_posts = "ea4baf885b60cbf664b34ee760397549"
  base_url = "https://www.instagram.com"
let
  r1 = re"instagram.com\/(.*?)\/$"

proc get_query_url(hash, vars: string): string =
  &"{base_url}/graphql/query/?query_hash={hash}&variables={vars}"

proc get_posts(user, endc: string): string =
  hash_posts.get_query_url "{\"id\":\"" & user & "\", \"after\":\"" & endc & "\", \"first\":12}"

proc ex_user(n: JsonNode): JsonNode =
  if n.hasKey "data":
    return n["data"]["user"]
  n["graphql"]["user"]

proc ex_timeline(n: JsonNode): JsonNode =
  n.ex_user["edge_owner_to_timeline_media"]

proc ex_stories(n: JsonNode): JsonNode =
  n.ex_user["edge_felix_video_timeline"]

proc get_session(user, pass: string): Session =
  # let res = fetch(base_url & "/accounts/login/")
  
  # let t = getTime().toUnix()
  # let enc_pass = &"#PWD_INSTAGRAM_BROWSER:0:{t}:{pass}"
  discard

scraper "instagram":
  arg v_ar1, "arg1"
  match re"instagram.com"
  exec:
    if not xurl.empty: v_ar1 = $xurl
    rcase v_ar1:
      rof r1:
        let api_url_user = v_ar1.parseUrl
        api_url_user.query["__a"] = "1"
        var page_url = api_url_user
        var user_id = ""
        log $page_url
        while not page_url.empty:
          jpage page_url, captures[0].get:
            if user_id == "":
              user_id = data.ex_user["id"].getStr
            let timeline = data.ex_timeline
            let stories = data.ex_stories

            # add timeline media
            for cnode in timeline["edges"].getElems:
              try:
                let node = cnode["node"]
                let du = node["display_url"].getStr
                urls.add du
              except Exception:
                err getCurrentExceptionMsg()
                
            if timeline["page_info"]["has_next_page"].getBool:
              let cur = timeline["page_info"]["end_cursor"].getStr
              page_url = user_id.get_posts(cur).parseUrl
            else: page_url = "".parseUrl