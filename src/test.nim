const
  LEFT   = 0x01
  RIGHT  = 0x02
  UP     = 0x04
  DOWN   = 0x08
  H_DBL  = 0x10
  V_DBL  = 0x20

  HORIZ = LEFT or RIGHT
  VERT  = UP or DOWN

var gBoxCharsUnicode: array[64, string]

gBoxCharsUnicode[0] = " "

gBoxCharsUnicode[   0 or  0 or     0 or    0] = " "
gBoxCharsUnicode[   0 or  0 or     0 or LEFT] = "─"
gBoxCharsUnicode[   0 or  0 or RIGHT or    0] = "─"
gBoxCharsUnicode[   0 or  0 or RIGHT or LEFT] = "─"
gBoxCharsUnicode[   0 or UP or     0 or    0] = "│"
gBoxCharsUnicode[   0 or UP or     0 or LEFT] = "┘"
gBoxCharsUnicode[   0 or UP or RIGHT or    0] = "└"
gBoxCharsUnicode[   0 or UP or RIGHT or LEFT] = "┴"
gBoxCharsUnicode[DOWN or  0 or     0 or    0] = "│"
gBoxCharsUnicode[DOWN or  0 or     0 or LEFT] = "┐"
gBoxCharsUnicode[DOWN or  0 or RIGHT or    0] = "┌"
gBoxCharsUnicode[DOWN or  0 or RIGHT or LEFT] = "┬"
gBoxCharsUnicode[DOWN or UP or     0 or    0] = "│"
gBoxCharsUnicode[DOWN or UP or     0 or LEFT] = "┤"
gBoxCharsUnicode[DOWN or UP or RIGHT or    0] = "├"
gBoxCharsUnicode[DOWN or UP or RIGHT or LEFT] = "┼"

gBoxCharsUnicode[H_DBL or    0 or  0 or     0 or    0] = " "
gBoxCharsUnicode[H_DBL or    0 or  0 or     0 or LEFT] = "═"
gBoxCharsUnicode[H_DBL or    0 or  0 or RIGHT or    0] = "═"
gBoxCharsUnicode[H_DBL or    0 or  0 or RIGHT or LEFT] = "═"
gBoxCharsUnicode[H_DBL or    0 or UP or     0 or    0] = "│"
gBoxCharsUnicode[H_DBL or    0 or UP or     0 or LEFT] = "╛"
gBoxCharsUnicode[H_DBL or    0 or UP or RIGHT or    0] = "╘"
gBoxCharsUnicode[H_DBL or    0 or UP or RIGHT or LEFT] = "╧"
gBoxCharsUnicode[H_DBL or DOWN or  0 or     0 or    0] = "│"
gBoxCharsUnicode[H_DBL or DOWN or  0 or     0 or LEFT] = "╕"
gBoxCharsUnicode[H_DBL or DOWN or  0 or RIGHT or    0] = "╒"
gBoxCharsUnicode[H_DBL or DOWN or  0 or RIGHT or LEFT] = "╤"
gBoxCharsUnicode[H_DBL or DOWN or UP or     0 or    0] = "│"
gBoxCharsUnicode[H_DBL or DOWN or UP or     0 or LEFT] = "╡"
gBoxCharsUnicode[H_DBL or DOWN or UP or RIGHT or    0] = "╞"
gBoxCharsUnicode[H_DBL or DOWN or UP or RIGHT or LEFT] = "╪"

gBoxCharsUnicode[V_DBL or    0 or  0 or     0 or    0] = " "
gBoxCharsUnicode[V_DBL or    0 or  0 or     0 or LEFT] = "─"
gBoxCharsUnicode[V_DBL or    0 or  0 or RIGHT or    0] = "─"
gBoxCharsUnicode[V_DBL or    0 or  0 or RIGHT or LEFT] = "─"
gBoxCharsUnicode[V_DBL or    0 or UP or     0 or    0] = "║"
gBoxCharsUnicode[V_DBL or    0 or UP or     0 or LEFT] = "╜"
gBoxCharsUnicode[V_DBL or    0 or UP or RIGHT or    0] = "╙"
gBoxCharsUnicode[V_DBL or    0 or UP or RIGHT or LEFT] = "╨"
gBoxCharsUnicode[V_DBL or DOWN or  0 or     0 or    0] = "║"
gBoxCharsUnicode[V_DBL or DOWN or  0 or     0 or LEFT] = "╖"
gBoxCharsUnicode[V_DBL or DOWN or  0 or RIGHT or    0] = "╓"
gBoxCharsUnicode[V_DBL or DOWN or  0 or RIGHT or LEFT] = "╥"
gBoxCharsUnicode[V_DBL or DOWN or UP or     0 or    0] = "║"
gBoxCharsUnicode[V_DBL or DOWN or UP or     0 or LEFT] = "╢"
gBoxCharsUnicode[V_DBL or DOWN or UP or RIGHT or    0] = "╟"
gBoxCharsUnicode[V_DBL or DOWN or UP or RIGHT or LEFT] = "╫"

gBoxCharsUnicode[H_DBL or V_DBL or    0 or  0 or     0 or    0] = " "
gBoxCharsUnicode[H_DBL or V_DBL or    0 or  0 or     0 or LEFT] = "═"
gBoxCharsUnicode[H_DBL or V_DBL or    0 or  0 or RIGHT or    0] = "═"
gBoxCharsUnicode[H_DBL or V_DBL or    0 or  0 or RIGHT or LEFT] = "═"
gBoxCharsUnicode[H_DBL or V_DBL or    0 or UP or     0 or    0] = "║"
gBoxCharsUnicode[H_DBL or V_DBL or    0 or UP or     0 or LEFT] = "╝"
gBoxCharsUnicode[H_DBL or V_DBL or    0 or UP or RIGHT or    0] = "╚"
gBoxCharsUnicode[H_DBL or V_DBL or    0 or UP or RIGHT or LEFT] = "╩"
gBoxCharsUnicode[H_DBL or V_DBL or DOWN or  0 or     0 or    0] = "║"
gBoxCharsUnicode[H_DBL or V_DBL or DOWN or  0 or     0 or LEFT] = "╗"
gBoxCharsUnicode[H_DBL or V_DBL or DOWN or  0 or RIGHT or    0] = "╔"
gBoxCharsUnicode[H_DBL or V_DBL or DOWN or  0 or RIGHT or LEFT] = "╦"
gBoxCharsUnicode[H_DBL or V_DBL or DOWN or UP or     0 or    0] = "║"
gBoxCharsUnicode[H_DBL or V_DBL or DOWN or UP or     0 or LEFT] = "╣"
gBoxCharsUnicode[H_DBL or V_DBL or DOWN or UP or RIGHT or    0] = "╠"
gBoxCharsUnicode[H_DBL or V_DBL or DOWN or UP or RIGHT or LEFT] = "╬"


const vs = [" ", "─", "─", "─", "│", "┘", "└", "┴", "│", "┐", "┌", "┬", "│", "┤", "├", "┼", " ", "═", "═", "═", "│", "╛", "╘", "╧", "│", "╕", "╒", "╤", "│", "╡", "╞", "╪", " ", "─", "─", "─", "║", "╜", "╙", "╨", "║", "╖", "╓", "╥", "║", "╢", "╟", "╫", " ", "═", "═", "═", "║", "╝", "╚", "╩", "║", "╗", "╔", "╦", "║", "╣", "╠", "╬"]

assert vs == gBoxCharsUnicode