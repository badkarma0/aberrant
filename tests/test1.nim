# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest


import os, ../src/libscrape
# proc w {.thread.} =
#   while true:
#     sleep 1000
#     echo "..."
#     break
  
# test "threads":
#   var ts: array[10,Thread[void]]
#   for i in 0..ts.high:
#     ts[i].createThread w
#   ts.joinThreads


test "break":
  while true:
    if true:
      echo "break"
      break
    sleep 1000

test "case":
  proc hello =
    echo "hello"
  # proc h_e_l_l_o =
  #   echo "hello"
  he_ll_o()

test "url combine":
  var u1 = parseUrl "https://famousinternetgirls.com/video/dejatualma-wine-bottle-pussy-fuck-onlyfans-leaked-videos/"
  var u2 = parseUrl "https://famousinternetgirls.com/wp-content/themes/videotube/img/logo.png"
  echo u1.combine u2

test "json string":
  echo "1000".parseJson.to int
  echo "\"1000\"".parseJson.to string
  echo "1000".parseJson.to string

test "or":
  echo if "" != "": "" else: "/"