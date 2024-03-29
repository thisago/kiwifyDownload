# Package

version       = "1.2.2"
author        = "Thiago Navarro"
description   = "Downloads the kiwify videos from course JSON"
license       = "MIT"
srcDir        = "src"
bin           = @["kiwifyDownload"]
binDir = "build"


# Dependencies

requires "nim >= 1.6.4"
requires "cligen"
requires "util"
