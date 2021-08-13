import db_sqlite, os, nre, url, util, json, os, times
# import parsecfg
import strutils
import asyncdispatch, asynchttpserver, asyncnet
# var dict = loadConfig("autoindex.ini")

type
  FileData = ref object
    name, path: string
    size: int
    modified: float

# let
#   port = dict.getSectionValue("main", "port")
#   host = dict.getSectionValue("main", "host")
#   root = dict.getSectionValue("main", "root")
#   prefix = dict.getSectionValue("main", "prefix")
let 
  root = "./"
  prefix = "/api/index"

template gcon(body) =
  var db {.inject.} = open(root / "index.db", "", "", "")
  block: body
  db.close()

proc init_db: string =
  gcon:
    db.exec(sql"""
create table if not exists files
(
	name TEXT not null,
	path TEXT not null,
	size INTEGER,
	modified INTEGER
)
     """)
  return "done"

func file_data_from_row(row: Row): FileData = 
  FileData(name: row[0], path: row[1],
    size: row[2].parseInt, modified: row[3].parseFloat)

proc get_index(path, query: string): seq[FileData] =
  gcon:
    if query != "":
      let r = query.re
      for row in db.fastRows(sql"""SELECT * FROM files WHERE path LIKE "?%" """, path):
        if row[0].contains(r):
          result.add row.file_data_from_row
    else:
      for row in db.fastRows(sql"SELECT * FROM files WHERE path = ?", path):
        result.add row.file_data_from_row

proc crawlfs(path: string, db: DbConn, recurse: bool): BiggestInt =
  echo "AutoIndex :: Crawling " & path
  var 
    dirs: seq[(string,string,string,float)]
    dir_size:BiggestInt = 0
  for kind, name in path.walkDir(true):
    var
      fname = name
    if kind == pcDir:
      fname &= "/"
    let
      fpath = path / fname
      info = fpath.getFileInfo(false)
      modified = info.lastWriteTime.toUnixFloat
      size = info.size
      vpath = fpath.replace(root, "")
    var ps = prepare(db, "INSERT INTO files VALUES (?,?,?,?)")
    if kind == pcDir:
      if recurse:
        dirs.add (name,vpath,fpath,modified)
      else:
        bindParams(ps, fname, vpath, size, modified)
        db.exec ps
    else:
      dir_size += size
      bindParams(ps, fname, vpath, size, modified)
      db.exec ps
    ps.finalize  
    
  if recurse:
    for dir in dirs:
      var ps = prepare(db, "INSERT INTO files VALUES (?,?,?,?)")
      let n_dir_size = crawlfs(dir[2], db, recurse) or 0      
      ps.bindParams dir[0], dir[1], n_dir_size, dir[3]
      db.exec ps
      ps.finalize  
      dir_size += n_dir_size
  dir_size

proc reindex(path: string, recurse = false): string =
  var rpath = root / path
  if rpath[^1] != '/':
    rpath &= "/"
  gcon:
    if recurse:
      db.exec(sql"""DELETE FROM files WHERE path LIKE "?%" """, path)
    else:
      db.exec(sql"""DELETE FROM files WHERE path = "?" """, path)
    db.exec(sql"BEGIN")
    time "crawlfs":
      discard crawlfs(rpath, db, recurse)
    db.exec(sql"COMMIT")

  return "done"

proc iresp[T](req: Request, res: T) {.async.} = 
  let h = newHttpHeaders([("Content-Type", "application/json"), 
    ("Access-Control-Allow-Origin", "*")])
  await req.respond(Http200, $(%*res), h)

template pcase(path: string, b: untyped) =
  template pof(bp: string, bb: untyped) =
    if path.normalizedPath.cmpPaths(bp.normalizedPath) == 0:
      bb
  b

proc handle_autoindex_request*(req: Request)  {.async.} =
  {.cast(gcsafe).}:
    let url = req.url.toUrl
    echo "AutoIndex :: Request " & url.path, " ", $url.query
    let 
      path = url.query.getOrDefault("path", "/")
      q = url.query.getOrDefault("q", "")
      recurse = url.query.getOrDefault("recurse", "false").parseBool
    pcase url.path:
      pof prefix:
        await req.iresp get_index(path, q)
      pof prefix / "reindex":
        await req.iresp reindex(path, recurse)
      pof prefix / "init":
        await req.iresp init_db()

