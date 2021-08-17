## Parses URLs and URLs
##
##  The following are two example URLs and their component parts:
##        foo://admin:hunter1@example.com:8042/over/there?name=ferret#nose
##        \_/   \___/ \_____/ \_________/ \__/\_________/ \_________/ \__/
##         |      |       |       |        |       |          |         |
##      scheme username password hostname port   path       query fragment
##
##  
## this is a merge of treeform/urlly and std/uri
##

import strutils, strtabs, uri
export strtabs

type
  Url* = ref object
    scheme*, username*, password*: string
    hostname*, port*, path*, fragment*: string
    query*: StringTableRef
func newUrl*: Url =
  Url(scheme: "", username: "", password: "", hostname: "",
    port: "", path: "", fragment: "", query: newStringTable())

func encodeUrlComponent*(s: string): string =
  ## Takes a string and encodes it in the URL format.
  result = newStringOfCap(s.len)
  for c in s:
    case c:
      of ' ':
        result.add '+'
      of 'a'..'z', 'A'..'Z', '0'..'9', '-', '.', '_', '~':
        result.add(c)
      else:
        result.add '%'
        result.add toHex(ord(c), 2)

func decodeUrlComponent*(s: string): string =
  ## Takes a string and decodes it from the URL format.
  result = newStringOfCap(s.len)
  var i = 0
  while i < s.len:
    case s[i]:
      of '%':
        result.add chr(fromHex[uint8](s[i+1 .. i+2]))
        i += 2
      of '+':
        result.add ' '
      else:
        result.add s[i]
    inc i

func host*(url: Url): string =
  ## Returns Host and port part of the URL as a string.
  ## Example: "example.com:8042"
  return url.hostname & ":" & url.port

func search*(url: Url): string =
  ## Returns the search part of the URL as a string.
  ## Example: "name=ferret&age=12&legs=4"
  var i = 0
  for (key,value) in url.query.pairs:
    if i > 0:
      result.add '&'
    inc i
    result.add encodeUrlComponent(key)
    result.add '='
    result.add encodeUrlComponent(value)

func authority*(url: Url): string =
  ## Returns the authority part of URL as a string.
  ## Example: "admin:hunter1@example.com:8042"
  if url.username.len > 0:
    result.add url.username
    if url.password.len > 0:
      result.add ':'
      result.add url.password
    result.add '@'
  if url.hostname.len > 0:
    result.add url.hostname
  if url.port.len > 0:
    result.add ':'
    result.add url.port

func `$`*(url: Url): string =
  ## Turns Url into a string. Preserves query string param ordering.
  if url.scheme.len > 0:
    result.add url.scheme
    result.add "://"
  result.add url.authority
  if url.path.len > 0:
    if url.path[0] != '/':
      result.add '/'
    result.add url.path
  if url.query.len > 0:
    result.add '?'
    result.add url.search
  if url.fragment.len > 0:
    result.add '#'
    result.add url.fragment

func parseUrl*(s: string): Url =
  ## Parses a URL or a URL into the Url object.
  var s = s
  var url = newUrl()

  let hasFragment = s.rfind('#')
  if hasFragment != -1:
    url.fragment = s[hasFragment + 1 .. ^1]
    s = s[0 .. hasFragment - 1]

  let hasSearch = s.rfind('?')
  if hasSearch != -1:
    let search = s[hasSearch + 1 .. ^1]
    s = s[0 .. hasSearch - 1]

    for pairStr in search.split('&'):
      let pair = pairStr.split('=', 1)
      let kv =
        if pair.len == 2:
          (decodeUrlComponent(pair[0]), decodeUrlComponent(pair[1]))
        elif pair.len == 1:
          (decodeUrlComponent(pair[0]), "")
        else:
          ("", "")
      url.query[kv[0]] = kv[1]

  let hasScheme = s.find("://")
  if hasScheme != -1:
    url.scheme = s[0 .. hasScheme - 1]
    s = s[hasScheme + 3 .. ^1]

  let hasLogin = s.find('@')
  if hasLogin != -1:
    let login = s[0 .. hasLogin - 1]
    let hasPassword = login.find(':')
    if hasPassword != -1:
      url.username = login[0 .. hasPassword - 1]
      url.password = login[hasPassword + 1 .. ^1]
    else:
      url.username = login
    s = s[hasLogin + 1 .. ^1]

  let hasPath = s.find('/')
  if hasPath != -1:
    url.path = s[hasPath .. ^1]
    s = s[0 .. hasPath - 1]

  let hasPort = s.find(':')
  if hasPort != -1:
    url.port = s[hasPort + 1 .. ^1]
    s = s[0 .. hasPort - 1]

  url.hostname = s
  return url


func removeDotSegments(path: string): string =
  if path.len == 0: return ""
  var collection: seq[string] = @[]
  let endsWithSlash = path[path.len-1] == '/'
  var i = 0
  var currentSegment = ""
  while i < path.len:
    case path[i]
    of '/':
      collection.add(currentSegment)
      currentSegment = ""
    of '.':
      if i+2 < path.len and path[i+1] == '.' and path[i+2] == '/':
        if collection.len > 0:
          discard collection.pop()
          i.inc 3
          continue
      elif i + 1 < path.len and path[i+1] == '/':
        i.inc 2
        continue
      currentSegment.add path[i]
    else:
      currentSegment.add path[i]
    i.inc
  if currentSegment != "":
    collection.add currentSegment

  result = collection.join("/")
  if endsWithSlash: result.add '/'

func merge(base, reference: Url): string =
  # http://tools.ietf.org/html/rfc3986#section-5.2.3
  if base.hostname != "" and base.path == "":
    '/' & reference.path
  else:
    let lastSegment = rfind(base.path, "/")
    if lastSegment == -1:
      reference.path
    else:
      base.path[0 .. lastSegment] & reference.path

func combine*(base: Url, reference: Url): Url =
  ## Combines a base URI with a reference URI.
  ##
  ## This uses the algorithm specified in
  ## `section 5.2.2 of RFC 3986 <http://tools.ietf.org/html/rfc3986#section-5.2.2>`_.
  ##
  ## This means that the slashes inside the base URIs path as well as reference
  ## URIs path affect the resulting URI.
  ##
  ## **See also:**
  ## * `/ func <#/,Url,string>`_ for building URIs
  runnableExamples:
    let foo = combine(parseUri("https://nim-lang.org/foo/bar"), parseUri("/baz"))
    assert foo.path == "/baz"
    let bar = combine(parseUri("https://nim-lang.org/foo/bar"), parseUri("baz"))
    assert bar.path == "/foo/baz"
    let qux = combine(parseUri("https://nim-lang.org/foo/bar/"), parseUri("baz"))
    assert qux.path == "/foo/bar/baz"

  result = newUrl()

  func setAuthority(dest: var Url, src: Url) =
    dest.hostname = src.hostname
    dest.username = src.username
    dest.port = src.port
    dest.password = src.password

  if reference.scheme != base.scheme and reference.scheme != "":
    result = reference
    result.path = removeDotSegments(result.path)
  else:
    if reference.hostname != "":
      setAuthority(result, reference)
      result.path = removeDotSegments(reference.path)
      result.query = reference.query
    else:
      if reference.path == "":
        result.path = base.path
        if $reference.query != "":
          result.query = reference.query
        else:
          result.query = base.query
      else:
        if reference.path.startsWith("/"):
          result.path = removeDotSegments(reference.path)
        else:
          result.path = removeDotSegments(merge(base, reference))
        result.query = reference.query
      setAuthority(result, base)
    result.scheme = base.scheme

func combine*(uris: varargs[Url]): Url =
  ## Combines multiple URIs together.
  ##
  ## **See also:**
  ## * `/ func <#/,Url,string>`_ for building URIs
  runnableExamples:
    let foo = combine(parseUri("https://nim-lang.org/"), parseUri("docs/"),
        parseUri("manual.html"))
    assert foo.hostname == "nim-lang.org"
    assert foo.path == "/docs/manual.html"
  result = uris[0]
  for i in 1 ..< uris.len:
    result = combine(result, uris[i])

func isAbsolute*(uri: Url): bool =
  ## Returns true if URI is absolute, false otherwise.
  runnableExamples:
    let foo = parseUri("https://nim-lang.org")
    assert isAbsolute(foo) == true
    let bar = parseUri("nim-lang")
    assert isAbsolute(bar) == false
  return uri.scheme != "" and (uri.hostname != "" or uri.path != "")

func `/`*(x: Url, path: string): Url =
  ## Concatenates the path specified to the specified URIs path.
  ##
  ## Contrary to the `combine func <#combine,Url,Url>`_ you do not have to worry about
  ## the slashes at the beginning and end of the path and URIs path
  ## respectively.
  ##
  ## **See also:**
  ## * `combine func <#combine,Url,Url>`_
  runnableExamples:
    let foo = parseUri("https://nim-lang.org/foo/bar") / "/baz"
    assert foo.path == "/foo/bar/baz"
    let bar = parseUri("https://nim-lang.org/foo/bar") / "baz"
    assert bar.path == "/foo/bar/baz"
    let qux = parseUri("https://nim-lang.org/foo/bar/") / "baz"
    assert qux.path == "/foo/bar/baz"
  result = parseUrl $x

  if result.path.len == 0:
    if path.len == 0 or path[0] != '/':
      result.path = "/"
    result.path.add(path)
    return

  if result.path.len > 0 and result.path[result.path.len-1] == '/':
    if path.len > 0 and path[0] == '/':
      result.path.add(path[1 .. path.len-1])
    else:
      result.path.add(path)
  else:
    if path.len == 0 or path[0] != '/':
      result.path.add '/'
    result.path.add(path)


proc toUrl*(u: Uri): Url = parseUrl($u)
