# Package

version       = "0.4.0"
author        = "PsychoClay"
description   = "web scraper"
license       = "WTFPL"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["aberrant"]


# Dependencies

requires "nim >= 1.4.8"
requires "ws"
requires "nimquery"
requires "termstyle"