
# var 
#   f1 = open("x.txt", fmReadWrite)
#   f2 = open("x.txt", fmReadWrite)

# f1.write("hello")
# f1.flushFile()

# f2.setFilePos(20)
# f2.write("xxxxx")
# f2.setFilePos(0)
# var b: seq[int8] = newSeq[int8](100)
# echo f2.readBytes(b, 0 ,100)
# echo b

type
  Xx = ref object
    i: int

var xs: seq[Xx]
for i in 0..3:
  var cx = new Xx
  xs.add cx
  echo cx.unsafeAddr.repr

for i in xs:
  i.i = 20
  echo i.unsafeAddr.repr
