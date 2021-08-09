# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest


import os
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

