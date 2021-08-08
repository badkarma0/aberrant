import asyncdispatch

proc the_end_of_time(m:string) {.async.} =
  while true:
    await sleepAsync(1000)
    echo "loop " & m

proc important1 {.async.} =
  await the_end_of_time("1")

proc important2 {.async.} =
  await the_end_of_time("2")

proc run =
  asyncCheck important1()
  echo "this never gets echoed"
  asyncCheck important2()

run()
runForever()
