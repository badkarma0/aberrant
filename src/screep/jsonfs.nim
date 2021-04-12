import json
import os
import strutils

type
  JsonFS* = JsonNode

template t(fs: JsonFS, path: string) =
  if path == "": return
  if fs.kind != JObject: return
  let sp = path.split('/')
  let head {.inject.} = sp[0]
  let tail {.inject.} = sp[1..^1].join "/"
  
proc create*(fs: JsonFS, path: string) =
  t fs, path
  if head in fs and fs[head].kind == JObject:
    create(fs[head], tail)
  elif tail == "":
    fs[head] = newJInt(0)  
  else:
    fs[head] = newJObject()
    create(fs[head], tail)

proc has*(fs: JsonFS, path: string): bool =
  t fs, path
  if head in fs:
    if tail == "":
      return true
    return (fs[head].has tail)
  return false

proc newJFS*: JsonFS =
  return newJObject()

when isMainModule:
  var testFs: JsonFS = newJObject()
  testFs.create "some/path/that/is.txt"
  testFs.create "some/path/file.txt"
  testFs.create "some/other"
  testFs.create "some/other/that/is.txt"
  testFs.create "some/other/that/is.txt/somethin"
  testFs.create "some/other"

  echo  testFs.has "some/other"
  echo  testFs.has "some/other/fffff"
  echo  testFs.has "some/other/that/is.txt"

  "test".createDir
  writeFile("test/test.json", $testFs)
  